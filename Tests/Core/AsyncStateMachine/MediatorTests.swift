import StateMachineShared
import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class MediatorTests: XCTestCase, @unchecked Sendable {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = Mediator<MockSuperEvent>()

    receiver = AsyncStateMachine(stateMachine: StateMachine(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: TestedState.loading)
        }
      }
    })
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
    receiver = nil
  }

  // MARK: - Properties

  var sut: Mediator<MockSuperEvent>!
  var receiver: AsyncStateMachine<MockSuperState, MockSuperEvent>!

  // MARK: - Methods

  func test_register_receiver_setsReceiver() async {
    let expectedEvent = TestedEvent.loadingRequestedWithValue1701

    // Given an async state machine

    // When
    sut.register(receiver: receiver)

    // Then
    sut.sendToReceivers(event: expectedEvent)

    var iterator = receiver.eventStream.makeAsyncIterator()
    let receivedEvent = await iterator.next()!

    XCTAssertEqual(anyLhs: receivedEvent.event, anyRhs: expectedEvent)
  }

  // swiftlint:disable:next function_body_length
  func test_register_senderAndTowReceivers_connectsSenderToReceivers() {
    let receiverHasProducedTheLoadingState = expectation(description: "The receiver has produced the Loading state")
    receiverHasProducedTheLoadingState.expectedFulfillmentCount = 2

    let expectedSenderInitialState = TestedState.senderIdle
    let expectedSenderEvent = TestedEvent.senderLoadingRequested
    let expectedSenderNewState = TestedState.senderLoading

    let receivedId = SendableStorage<UUID?>(value: nil)
    let receivedState = SendableStorage<(any State<SenderMockSuperState>)?>(value: nil)
    let receivedEvent = SendableStorage<(any Event<SenderMockSuperEvent>)?>(value: nil)
    let receivedNewState = SendableStorage<(any State<SenderMockSuperState>)?>(value: nil)

    // Given
    let sender = AsyncStateMachine(stateMachine: StateMachine(initial: expectedSenderInitialState) {
      When(state: SenderIdle.self) {
        On(event: SenderLoadingWasRequested.self) { _, _ in
          Transition(state: expectedSenderNewState)
        }
      }
    })

    let secondReceiver = AsyncStateMachine(stateMachine: StateMachine(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: TestedState.loading)
        }
      }
    })
    sut.register(receiver: receiver)
    sut.register(receiver: secondReceiver)

    sut.register(sender: sender) { id, state, event, newState in
      receivedId.set(value: id)
      receivedState.set(value: state)
      receivedEvent.set(value: event)
      receivedNewState.set(value: newState)
      return LoadingWasRequested(id: 1701)
    }

    let receiverTask = Task {
      for await state in receiver {
        if state is Loading {
          receiverHasProducedTheLoadingState.fulfill()
        }
      }
    }

    let secondReceiverTask = Task {
      for await state in secondReceiver {
        if state is Loading {
          receiverHasProducedTheLoadingState.fulfill()
        }
      }
    }

    let senderTask = Task {
      for await _ in sender { }
    }

    // When
    sender.send(event: expectedSenderEvent)

    // Then
    wait(for: [receiverHasProducedTheLoadingState], timeout: 1.0)

    receivedId.assertEqual(expected: sender.id)
    receivedState.assertEqual(expected: expectedSenderInitialState)
    receivedEvent.assertEqual(expected: expectedSenderEvent)
    receivedNewState.assertEqual(expected: expectedSenderNewState)

    receiverTask.cancel()
    secondReceiverTask.cancel()
    senderTask.cancel()
  }

  func test_register_senderAndReceiver_connectsSenderToReceiver() {
    let receiverHasProducedTheLoadingState = expectation(description: "The receiver has produced the Loading state")

    let expectedSenderInitialState = TestedState.senderIdle
    let expectedSenderEvent = TestedEvent.senderLoadingRequested
    let expectedSenderNewState = TestedState.senderLoading

    let receivedId = SendableStorage<UUID?>(value: nil)
    let receivedState = SendableStorage<(any State<SenderMockSuperState>)?>(value: nil)
    let receivedEvent = SendableStorage<(any Event<SenderMockSuperEvent>)?>(value: nil)
    let receivedNewState = SendableStorage<(any State<SenderMockSuperState>)?>(value: nil)

    // Given
    let sender = AsyncStateMachine(stateMachine: StateMachine(initial: expectedSenderInitialState) {
      When(state: SenderIdle.self) {
        On(event: SenderLoadingWasRequested.self) { _, _ in
          Transition(state: expectedSenderNewState)
        }
      }
    })

    sut.register(receiver: receiver)
    sut.register(sender: sender) { id, state, event, newState in
      receivedId.set(value: id)
      receivedState.set(value: state)
      receivedEvent.set(value: event)
      receivedNewState.set(value: newState)
      return LoadingWasRequested(id: 1701)
    }

    let receiverTask = Task {
      for await state in receiver {
        if state is Loading {
          receiverHasProducedTheLoadingState.fulfill()
        }
      }
    }

    let senderTask = Task {
      for await _ in sender { }
    }

    // When
    sender.send(event: expectedSenderEvent)

    // Then
    wait(for: [receiverHasProducedTheLoadingState], timeout: 1.0)

    receivedId.assertEqual(expected: sender.id)
    receivedState.assertEqual(expected: expectedSenderInitialState)
    receivedEvent.assertEqual(expected: expectedSenderEvent)
    receivedNewState.assertEqual(expected: expectedSenderNewState)

    receiverTask.cancel()
    senderTask.cancel()
  }

  func test_register_whenReceiverWasDeallocated_removeReceiverFromList() {
    // Given
    sut.register(receiver: receiver)

    // When
    receiver = nil

    // Then
    let receivers = sut.receiversStorage.get().values

    XCTAssertTrue(
      receivers.isEmpty,
      """
      Expected receivers to be empty),
      but got \(receivers.count) receivers instead.
      """
    )
  }

  // swiftlint:disable:next function_body_length
  func test_send_whenSenderAndReceiverSetButEventNil_sendsNothingToReceiver() {
    let receiverHasProducedTheLoadingState = expectation(description: "The receiver has produced the Loading state")

    let expectedSenderInitialState = TestedState.senderIdle
    let expectedSenderSecondState = TestedState.senderLoading

    let expectedSenderFirstEvent = TestedEvent.senderLoadingRequested
    let expectedSenderSecondEvent = TestedEvent.senderLoadingSucceeded

    let receivedStates = SendableStorage<[ObjectIdentifier: any State<SenderMockSuperState>]>(value: [:])
    let receivedEvents = SendableStorage<[ObjectIdentifier: any Event<SenderMockSuperEvent>]>(value: [:])

    // Given
    let sender = AsyncStateMachine(stateMachine: StateMachine(initial: expectedSenderInitialState) {
      When(state: SenderIdle.self) {
        On(event: SenderLoadingWasRequested.self) { _, _ in
          Transition(state: expectedSenderSecondState)
        }
      }

      When(state: SenderLoading.self) {
        On(event: SenderLoadingHasSucceeded.self) { _, _ in
          Transition(state: TestedState.senderLoaded)
        }
      }
    })

    sut.register(receiver: receiver)
    sut.register(sender: sender) { _, currentState, event, _ in
      receivedStates.apply { values in
        values[ObjectIdentifier(type(of: currentState.self))] = currentState
      }
      receivedEvents.apply { values in
        values[ObjectIdentifier(type(of: event.self))] = event
      }

      return currentState is SenderLoading && event is SenderLoadingHasSucceeded
        ? LoadingWasRequested(id: 1701)
        : nil
    }

    let receiverTask = Task {
      for await state in receiver {
        if state is Loading {
          receiverHasProducedTheLoadingState.fulfill()
        }
      }
    }

    let senderTask = Task {
      for await _ in sender { }
    }

    // When
    sender.send(event: expectedSenderFirstEvent)
    sender.send(event: expectedSenderSecondEvent)

    // Then
    wait(for: [receiverHasProducedTheLoadingState], timeout: 1.0)

    let collectedSenderStates = receivedStates.get()
    let senderIdleObjectIdentifier = ObjectIdentifier(SenderIdle.self)
    let senderLoadingObjectIdentifier = ObjectIdentifier(SenderLoading.self)

    let collectedSenderEvents = receivedEvents.get()
    let senderLoadingWasRequestedObjectIdentifier = ObjectIdentifier(SenderLoadingWasRequested.self)
    let senderLoadingHasSucceededObjectIdentifier = ObjectIdentifier(SenderLoadingHasSucceeded.self)

    let firstSenderStateCollected = collectedSenderStates[senderIdleObjectIdentifier] as? SenderIdle
    XCTAssertEqual(
      firstSenderStateCollected,
      expectedSenderInitialState,
      """
      Expected first sender state collected to be \(expectedSenderInitialState),
      but got \(String(describing: firstSenderStateCollected)) instead.
      """
    )

    let secondSenderStateCollected = collectedSenderStates[senderLoadingObjectIdentifier] as? SenderLoading
    XCTAssertEqual(
      secondSenderStateCollected,
      expectedSenderSecondState,
      """
      Expected second sender state collected to be \(expectedSenderSecondState),
      but got \(String(describing: secondSenderStateCollected)) instead.
      """
    )

    let firstSenderEventCollected =
      collectedSenderEvents[senderLoadingWasRequestedObjectIdentifier] as? SenderLoadingWasRequested
    XCTAssertEqual(
      firstSenderEventCollected,
      expectedSenderFirstEvent,
      """
      Expected first sender event collected to be \(expectedSenderFirstEvent),
      but got \(String(describing: firstSenderEventCollected)) instead.
      """
    )

    let secondSenderEventCollected =
      collectedSenderEvents[senderLoadingHasSucceededObjectIdentifier] as? SenderLoadingHasSucceeded
    XCTAssertEqual(
      secondSenderEventCollected,
      expectedSenderSecondEvent,
      """
      Expected second sender event collected to be \(expectedSenderSecondEvent),
      but got \(String(describing: secondSenderEventCollected)) instead.
      """
    )

    receiverTask.cancel()
    senderTask.cancel()
  }
}
