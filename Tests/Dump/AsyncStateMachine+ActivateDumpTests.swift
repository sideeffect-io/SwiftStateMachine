// swiftlint:disable implicitly_unwrapped_optional

import StateMachineShared
import XCTest
@testable import StateMachineCore
@testable import StateMachineDump

final class AsyncStateMachineActivateDumpTests: XCTestCase {
  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = AsyncStateMachine(initial: TestedState.idle) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: TestedState.loading)
        }
      }
    }

    spyDumpMediator = Mediator<DumpEvent>()
  }

  override func tearDown() {
    super.tearDown()
    sut = nil
    spyDumpMediator = nil
  }

  // MARK: - Properties

  var sut: AsyncStateMachine<MockSuperState, MockSuperEvent>!
  var spyDumpMediator: Mediator<DumpEvent>!

  // MARK: - Methods

  func test_activateDump_whenTransitioning_triggersTheMediatorForInitialStateAndSecondState() async {
    let mediatorWasTriggered = expectation(description: "The dump mediator was triggered")
    mediatorWasTriggered.expectedFulfillmentCount = 2

    let receivedEvents = SendableStorage<[ObjectIdentifier: any Event<DumpEvent>]>(value: [:])

    let sendableBlock: @Sendable (any Event<DumpEvent>) -> Void = { dumpEvent in
      receivedEvents.apply { values in
        if let didObserveTransitionEvent = dumpEvent as? DidObserveTransition {
          let state = didObserveTransitionEvent.state
          values[ObjectIdentifier(type(of: state.self))] = dumpEvent
        }
      }
      mediatorWasTriggered.fulfill()
    }

    spyDumpMediator.receiversStorage.apply { receiversMap in
      receiversMap[sut.id] = sendableBlock
    }

    // Given
    sut.activateDump(trackDeinit: false, dumpMediator: spyDumpMediator)

    // When
    sut.send(event: LoadingWasRequested(id: 1701))

    var iterator = sut.makeAsyncIterator()
    _ = await iterator.next()
    _ = await iterator.next()

    // Then
    await fulfillment(of: [mediatorWasTriggered], timeout: 1.0)

    let events = receivedEvents.get()
    let idleStateIdentifier = ObjectIdentifier(type(of: TestedState.idle.self))
    let loadingStateIdentifier = ObjectIdentifier(type(of: TestedState.loading.self))

    let receivedIdleDidObserveTransitionEvent = events[idleStateIdentifier] as? DidObserveTransition
    let expectedIdleDidObserveTransitionEvent = DidObserveTransition(stateMachineId: sut.id, state: TestedState.idle)

    let receivedLoadingDidObserveTransitionEvent = events[loadingStateIdentifier] as? DidObserveTransition
    let expectedLoadingDidObserveTransitionEvent = DidObserveTransition(
      stateMachineId: sut.id,
      state: TestedState.loading
    )

    XCTAssertEqual(
      receivedIdleDidObserveTransitionEvent,
      expectedIdleDidObserveTransitionEvent,
      """
      Expected first event collected to be \(expectedIdleDidObserveTransitionEvent),
      but got \(String(describing: receivedIdleDidObserveTransitionEvent)) instead.
      """
    )

    XCTAssertEqual(
      receivedLoadingDidObserveTransitionEvent,
      expectedLoadingDidObserveTransitionEvent,
      """
      Expected first event collected to be \(expectedLoadingDidObserveTransitionEvent),
      but got \(String(describing: receivedLoadingDidObserveTransitionEvent)) instead.
      """
    )
  }

  func test_activateDump_whenDeinit_triggersTheMediator() async {
    let expectedStateMachineId = sut.id

    let receivedEvent = SendableStorage<(any Event<DumpEvent>)?>(value: nil)
    let didReceiveDeinit = expectation(description: "The dump mediator receives ordered deinit")

    let sendableBlock: @Sendable (any Event<DumpEvent>) -> Void = { dumpEvent in
      if dumpEvent is DidObserveDeinit {
        receivedEvent.set(value: dumpEvent)
        didReceiveDeinit.fulfill()
      }
    }

    spyDumpMediator.receiversStorage.apply { receiversMap in
      receiversMap[sut.id] = sendableBlock
    }

    // Given
    sut.activateDump(trackDeinit: true, dumpMediator: spyDumpMediator)

    // When
    sut = nil

    await fulfillment(of: [didReceiveDeinit], timeout: 1.0)

    // Then
    XCTAssertEqual(
      anyLhs: receivedEvent.get()!,
      anyRhs: DidObserveDeinit(stateMachineId: expectedStateMachineId)
    )
  }
}
