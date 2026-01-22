import StateMachineCore
import StateMachineShared
import XCTest

// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable implicitly_unwrapped_optional

final class AsyncStateMachineMediatorTests: XCTestCase, @unchecked Sendable {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = Mediator<MockSuperEvent>()
    receiver = AsyncStateMachine(stateMachine: StateMachine(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: Loading())
        }
      }
    })
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
    receiver = nil
    sender = nil
  }

  // MARK: - Properties

  var sut: Mediator<MockSuperEvent>!
  var receiver: AsyncStateMachine<MockSuperState, MockSuperEvent>!
  var sender: AsyncStateMachine<SenderMockSuperState, SenderMockSuperEvent>!

  // MARK: - Methods

  func test_connect_whenAnyCurrentStateAnyEventAnyNewState_connectsSenderAndReceiver() async {
    let receiverHasReceivedTheLoadingWasRequestedEvent =
      expectation(description: "The receiver has received the LoadingWasRequested event")

    let expectedEventInReceiver = TestedEvent.loadingRequestedWithValue1701
    let receivedEventInReceiver = SendableStorage<LoadingWasRequested?>(value: nil)

    // Given
    receiver.onTransition { _, _, event, _ in
      if event is LoadingWasRequested {
        receivedEventInReceiver.set(value: event as? LoadingWasRequested)
        receiverHasReceivedTheLoadingWasRequestedEvent.fulfill()
      }
    }

    receiver.connectAsReceiver(to: sut)

    sender = AsyncStateMachine(stateMachine: StateMachine(initial: TestedState.senderIdle) {
      When(state: SenderIdle.self) {
        On(event: SenderLoadingWasRequested.self) { _, _ in
          Transition(state: TestedState.senderLoading)
        }
      }
    })

    sender.connectAsSender(to: sut) { _, _, _, _ in
      expectedEventInReceiver
    }

    let receiverTask = Task {
      for await _ in receiver { }
    }

    let senderTask = Task {
      for await _ in sender { }
    }

    // When
    sender.send(event: TestedEvent.senderLoadingRequested)

    // Then
    await fulfillment(of: [receiverHasReceivedTheLoadingWasRequestedEvent], timeout: 1.0)
    receiver.finish()

    receivedEventInReceiver.assertEqual(expected: expectedEventInReceiver)

    receiverTask.cancel()
    senderTask.cancel()
  }

  func test_connect_whenAnyCurrentStateConcreteEventAnyNewState_connectsSenderAndReceiver() async {
    let receiverHasReceivedTheLoadingWasRequestedEvent =
      expectation(description: "The receiver has received the LoadingWasRequested event")

    let expectedSenderInitialState = TestedState.senderIdle
    let expectedEventInReceiver = TestedEvent.loadingRequestedWithValue1701

    let receivedEventInReceiver = SendableStorage<LoadingWasRequested?>(value: nil)
    let receivedSenderInitialState = SendableStorage<SenderIdle?>(value: nil)

    // Given
    receiver.onTransition { _, _, event, _ in
      if event is LoadingWasRequested {
        receivedEventInReceiver.set(value: event as? LoadingWasRequested)
        receiverHasReceivedTheLoadingWasRequestedEvent.fulfill()
      }
    }

    receiver.connectAsReceiver(to: sut)

    sender = AsyncStateMachine(stateMachine: StateMachine(initial: expectedSenderInitialState) {
      When {
        SenderIdle.self
        SenderLoading.self
      } transitions: {
        On {
          SenderLoadingWasRequested.self
          SenderReloadingWasRequested.self
        } transition: { _, _ in
          Transition(state: SenderLoading())
        }
      }
    })

    sender.connectAsSender(
      to: sut,
      on: SenderLoadingWasRequested.self
    ) { state, _, _ in
      receivedSenderInitialState.set(value: state as? SenderIdle)
      return expectedEventInReceiver
    }

    let receiverTask = Task {
      for await _ in receiver { }
    }

    let senderTask = Task {
      for await _ in sender { }
    }

    // When
    sender.send(event: TestedEvent.senderLoadingRequested)
    sender.send(event: TestedEvent.senderReloadingRequested)

    // Then
    await fulfillment(of: [receiverHasReceivedTheLoadingWasRequestedEvent], timeout: 1.0)
    receiver.finish()

    receivedSenderInitialState.assertEqual(expected: expectedSenderInitialState)
    receivedEventInReceiver.assertEqual(expected: expectedEventInReceiver)

    receiverTask.cancel()
    senderTask.cancel()
  }

  func test_connect_whenConcreteCurrentStateAnyEventAnyNewState_connectsSenderAndReceiver() async {
    let receiverHasReceivedTheLoadingWasRequestedEvent =
      expectation(description: "The receiver has received the LoadingWasRequested event")

    let expectedSenderSecondEvent = TestedEvent.senderReloadingRequested
    let expectedEventInReceiver = TestedEvent.loadingRequestedWithValue1701

    let receivedEventInReceiver = SendableStorage<LoadingWasRequested?>(value: nil)
    let receivedSenderSecondEvent = SendableStorage<SenderReloadingWasRequested?>(value: nil)

    // Given
    receiver.onTransition { _, _, event, _ in
      if event is LoadingWasRequested {
        receivedEventInReceiver.set(value: event as? LoadingWasRequested)
        receiverHasReceivedTheLoadingWasRequestedEvent.fulfill()
      }
    }

    receiver.connectAsReceiver(to: sut)

    sender = AsyncStateMachine(stateMachine: StateMachine(initial: TestedState.senderIdle) {
      When {
        SenderIdle.self
        SenderLoading.self
      } transitions: {
        On {
          SenderLoadingWasRequested.self
          SenderReloadingWasRequested.self
        } transition: { _, _ in
          Transition(state: SenderLoading())
        }
      }
    })

    sender.connectAsSender(
      to: sut,
      whenCurrentState: SenderLoading.self
    ) { _, event, _ in
      receivedSenderSecondEvent.set(value: event as? SenderReloadingWasRequested)
      return expectedEventInReceiver
    }

    let receiverTask = Task {
      for await _ in receiver { }
    }

    let senderTask = Task {
      for await _ in sender { }
    }

    // When
    sender.send(event: TestedEvent.senderLoadingRequested)
    sender.send(event: expectedSenderSecondEvent)

    // Then
    await fulfillment(of: [receiverHasReceivedTheLoadingWasRequestedEvent], timeout: 1.0)
    receiver.finish()

    receivedSenderSecondEvent.assertEqual(expected: expectedSenderSecondEvent)
    receivedEventInReceiver.assertEqual(expected: expectedEventInReceiver)

    receiverTask.cancel()
    senderTask.cancel()
  }

  func test_connect_whenConcreteCurrentStateConcreteEventAnyNewState_connectsSenderAndReceiver() async {
    let receiverHasReceivedTheLoadingWasRequestedEvent =
      expectation(description: "The receiver has received the LoadingWasRequested event")

    let expectedEventInReceiver = LoadingWasRequested(id: 1701)
    let receivedEventInReceiver = SendableStorage<LoadingWasRequested?>(value: nil)

    // Given
    receiver.onTransition { _, _, event, _ in
      if event is LoadingWasRequested {
        receivedEventInReceiver.set(value: event as? LoadingWasRequested)
        receiverHasReceivedTheLoadingWasRequestedEvent.fulfill()
      }
    }

    receiver.connectAsReceiver(to: sut)

    sender = AsyncStateMachine(stateMachine: StateMachine(initial: SenderIdle()) {
      When {
        SenderIdle.self
        SenderLoading.self
      } transitions: {
        On(event: SenderLoadingWasRequested.self) { _, _ in
          Transition(state: SenderIdle())
        }
      }

      When(state: SenderIdle.self) {
        On(event: SenderReloadingWasRequested.self) { _, _ in
          Transition(state: SenderLoading())
        }
      }
    })

    sender.connectAsSender(
      to: sut,
      whenCurrentState: SenderIdle.self,
      on: SenderLoadingWasRequested.self
    ) { _, _, _ in
      expectedEventInReceiver
    }

    let receiverTask = Task {
      for await _ in receiver { }
    }

    let senderTask = Task {
      for await _ in sender { }
    }

    // When
    sender.send(event: SenderLoadingWasRequested(id: 1701))
    sender.send(event: SenderReloadingWasRequested(id: 1701))
    sender.send(event: SenderLoadingWasRequested(id: 1701))

    // Then
    await fulfillment(of: [receiverHasReceivedTheLoadingWasRequestedEvent], timeout: 1.0)
    receiver.finish()

    receivedEventInReceiver.assertEqual(expected: expectedEventInReceiver)

    receiverTask.cancel()
    senderTask.cancel()
  }

  func test_connect_whenAnyCurrentStateAnyEventConcreteNewState_connectsSenderAndReceiver() async {
    let receiverHasReceivedTheLoadingWasRequestedEvent =
      expectation(description: "The receiver has received the LoadingWasRequested event")

    let expectedSenderEvent = SenderLoadingWasRequested(id: Int.random(in: 0...100))
    let expectedEventInReceiver = LoadingWasRequested(id: 1701)

    let receivedEventInReceiver = SendableStorage<LoadingWasRequested?>(value: nil)
    let receivedSenderEvent = SendableStorage<SenderLoadingWasRequested?>(value: nil)

    // Given
    receiver.onTransition { _, _, event, _ in
      if event is LoadingWasRequested {
        receivedEventInReceiver.set(value: event as? LoadingWasRequested)
        receiverHasReceivedTheLoadingWasRequestedEvent.fulfill()
      }
    }

    receiver.connectAsReceiver(to: sut)

    sender = AsyncStateMachine(stateMachine: StateMachine(initial: SenderIdle()) {
      When(state: SenderIdle.self) {
        On(event: SenderLoadingWasRequested.self) { _, _ in
          Transition(state: SenderLoading())
        }
      }

      When(state: SenderLoading.self) {
        On(event: SenderLoadingHasSucceeded.self) { _, _ in
          Transition(state: SenderLoaded())
        }
      }
    })

    sender.connectAsSender(
      to: sut,
      whenNewState: SenderLoading.self
    ) { _, event, _ in
      receivedSenderEvent.set(value: event as? SenderLoadingWasRequested)
      return expectedEventInReceiver
    }

    let receiverTask = Task {
      for await _ in receiver { }
    }

    let senderTask = Task {
      for await _ in sender { }
    }

    // When
    sender.send(event: expectedSenderEvent)
    sender.send(event: SenderLoadingHasSucceeded(id: 1701))

    // Then
    await fulfillment(of: [receiverHasReceivedTheLoadingWasRequestedEvent], timeout: 1.0)
    receiver.finish()

    receivedSenderEvent.assertEqual(expected: expectedSenderEvent)
    receivedEventInReceiver.assertEqual(expected: expectedEventInReceiver)

    receiverTask.cancel()
    senderTask.cancel()
  }
}
