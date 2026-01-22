// swiftlint:disable implicitly_unwrapped_optional

import StateMachineShared
import StateMachineTest
import XCTest
@testable import StateMachineCore
@testable import StateMachineDump

final class DefaultDumpStateMachineTests: XCTestCase {
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
    sut = defaultDumpStateMachine
  }

  // MARK: - Properties

  var sut: AsyncStateMachine<DumpState, DumpEvent>!

  // MARK: - Methods

  func test_stateMachine_whenExecuted_hasExpectedBehaviour() async {
    let expectedStateMachineId1 = UUID()
    let expectedState1 = TestedState.loading
    let expectedDumpState1 = DumpState(
      stateContexts: [
        expectedStateMachineId1: StateContext(stateMachineId: expectedStateMachineId1, state: expectedState1),
      ]
    )

    let expectedStateMachineId2 = UUID()
    let expectedState2 = TestedState.loaded
    let expectedDumpState2 = DumpState(
      stateContexts: [
        expectedStateMachineId1: StateContext(stateMachineId: expectedStateMachineId1, state: expectedState1),
        expectedStateMachineId2: StateContext(stateMachineId: expectedStateMachineId2, state: expectedState2),
      ]
    )

    // Given
    await XCTAssert(asyncStateMachine: sut, shouldFinishAfterAssertions: false) { assertions in
      // When, Then
      await assertions.assert(state: DumpState(stateContexts: [:]))

      // When
      assertions.send(event: DidObserveTransition(stateMachineId: expectedStateMachineId1, state: expectedState1))

      // Then
      await assertions.assert(state: expectedDumpState1)

      // When
      assertions.send(event: DidObserveTransition(stateMachineId: expectedStateMachineId2, state: expectedState2))

      // Then
      await assertions.assert(state: expectedDumpState2)

      // When
      assertions.send(event: DidObserveDeinit(stateMachineId: expectedStateMachineId2))

      // Then
      await assertions.assert(state: expectedDumpState1)

      // When
      await assertions.sendAndWait(event: DidRequestDump { receivedStateContexts in
        let expectedStateContexts = expectedDumpState1.toStateContextArray()

        // Then
        XCTAssertEqual(
          receivedStateContexts,
          expectedStateContexts,
          "Expected StateContexts were \(expectedStateContexts), but got \(receivedStateContexts) instead"
        )
      })
    }
  }
}
