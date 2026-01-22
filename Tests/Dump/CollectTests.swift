import StateMachineShared
import XCTest
@testable import StateMachineCore
@testable import StateMachineDump

// MARK: - CollectTests

// swiftlint:disable implicitly_unwrapped_optional

final class CollectTests: XCTestCase, @unchecked Sendable {
  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()
    stopCollecting()
    sut.currentState.set(value: nil)
    sut.onTransitions.set(value: [])
    sut = nil
    mockDumpMediator = nil
  }

  override func setUp() {
    super.setUp()
    sut = makeMockDumpStateMachine()
    mockDumpMediator = Mediator<DumpEvent>()
  }

  // MARK: - Properties

  var sut: AsyncStateMachine<DumpState, DumpEvent>!
  var mockDumpMediator: Mediator<DumpEvent>!

  let clientStateMachine = AsyncStateMachine(initial: Idle()) {
    When(state: Idle.self) {
      On(event: LoadingWasRequested.self) { _, _ in
        Transition(state: TestedState.loading)
      }
    }
  }

  // MARK: - Methods

  func test_dumpStateMachine_whenStartCollecting_dumpStateMachineReceivesTransitions() {
    let expectedEvent = DidObserveTransition(stateMachineId: clientStateMachine.id, state: TestedState.loading)
    let dumpStateMachineHasTransitioned = expectation(description: "The dump state machine has transitioned")

    clientStateMachine.activateDump(trackDeinit: true, dumpMediator: mockDumpMediator)

    sut.onTransition { _, _, event, _ in
      if
        let didObserveTransitionEvent = event as? DidObserveTransition,
        expectedEvent == didObserveTransitionEvent
      {
        dumpStateMachineHasTransitioned.fulfill()
      }
    }

    // Given
    let clientTask = Task {
      for await _ in clientStateMachine { }
    }

    // When
    startCollecting(dumpStateMachine: sut, dumpMediator: mockDumpMediator)
    clientStateMachine.send(event: LoadingWasRequested(id: 1701))

    // Then
    wait(for: [dumpStateMachineHasTransitioned], timeout: 10.0)

    XCTAssertNotNil(
      collectTask,
      "The collect task should not be nil"
    )
    collectTask?.cancel()
    clientTask.cancel()
  }

  func test_dumpStateMachine_whenStopCollecting_stopsDumpStateMachineTask() {
    let dumpStateMachineHasTransitioned = expectation(description: "The dump state machine has transitioned")

    sut.onTransition { _, _, _, _ in
      dumpStateMachineHasTransitioned.fulfill()
    }

    // Given
    startCollecting(dumpStateMachine: sut, dumpMediator: mockDumpMediator)

    sut.send(event: DidObserveTransition(stateMachineId: UUID(), state: Loading()))

    // Then
    wait(for: [dumpStateMachineHasTransitioned], timeout: 1.0)

    // When
    stopCollecting()

    XCTAssertTrue(
      collectTask!.isCancelled,
      "The dump state machine task should be cancelled"
    )
  }
}

// MARK: - CollectTests+Tools

extension CollectTests {
  private func makeMockDumpStateMachine() -> AsyncStateMachine<DumpState, DumpEvent> {
    AsyncStateMachine<DumpState, DumpEvent>(initial: DumpState(stateContexts: [:])) {
      When(state: DumpState.self) {
        On(event: DidObserveTransition.self) { _, _ in
          Transition(state: DumpState(stateContexts: [:]))
        }
      }
    }
  }
}
