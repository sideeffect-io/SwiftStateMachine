import StateMachineShared
import XCTest
@testable import StateMachineCore
@testable import StateMachineDump

// MARK: - DumpTests

// swiftlint:disable implicitly_unwrapped_optional no_directStandardOutLogs

final class DumpTests: XCTestCase {
  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()
    stopCollecting()
    sut.currentState.set(value: nil)
    sut.onTransitions.set(value: [])
    sut = nil
  }

  override func setUp() {
    super.setUp()
    sut = makeMockDumpStateMachine()
  }

  // MARK: - Properties

  var sut: AsyncStateMachine<DumpState, DumpEvent>!

  // MARK: - Methods

  func test_dumpStateMachine_whenDump_executesExportFunction() {
    let dumpStateMachineHasTransitioned = expectation(description: "The dump state machine has transitioned")
    let mockDumpMediator = Mediator<DumpEvent>()

    sut.onTransition { _, _, event, _ in
      if event is DidRequestDump {
        dumpStateMachineHasTransitioned.fulfill()
      }
    }

    // Given
    startCollecting(dumpStateMachine: sut, dumpMediator: mockDumpMediator)

    // When
    StateMachineDump.dump(dumpStateMachine: sut) { _ in }

    // Then
    wait(for: [dumpStateMachineHasTransitioned], timeout: 2.0)
  }
}

// MARK: - DumpTests+Tools

extension DumpTests {
  private func makeMockDumpStateMachine() -> AsyncStateMachine<DumpState, DumpEvent> {
    AsyncStateMachine<DumpState, DumpEvent>(initial: DumpState(stateContexts: [:])) {
      When(state: DumpState.self) {
        On(event: DidRequestDump.self) { _, _ in
          Transition(state: DumpState(stateContexts: [:]))
        }
      }
    }
  }
}
