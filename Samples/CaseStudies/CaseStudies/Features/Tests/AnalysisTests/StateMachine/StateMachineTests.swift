import StateMachineCore
import StateMachineTest
import XCTest
@testable import Analysis

// swiftlint:disable implicitly_unwrapped_optional

final class StateMachineTests: XCTestCase {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = makeStateMachine(
      initial: TestedState.idle,
      performAnalysisOutput: TestedOutput.performAnalysisEmptyClosure
    )
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Types

  private enum TestedState {
    static let idle = AnalysisIsIdle()
    static let performing = AnalysisIsInProgress(identifier: 1701)
    static let performed = AnalysisIsDone(identifier: 1701)
  }

  private enum TestedEvent {
    static let newAnalysisRequested = DidRequestAnalysis(identifier: 1701)
    static let resetAnalysisRequested = DidRequestAnalysisReset()
  }

  private enum TestedOutput {
    static let performAnalysisEmptyClosure = PerformAnalysisOutput { }
  }

  // MARK: - Properties

  var sut: AsyncStateMachine<AnalysisState, AnalysisEvent>!

  // MARK: - Methods

  func test_send_validEvent_transitionsToExpectedState() async {
    // Given an async state machine

    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      // When / Then
      await assertions.assert(state: TestedState.idle)

      // When
      assertions.send(event: TestedEvent.newAnalysisRequested)
      // Then
      await assertions.assert(state: TestedState.performing)
      await assertions.assert(state: TestedState.performed)

      // When
      assertions.send(event: TestedEvent.resetAnalysisRequested)
      // Then
      await assertions.assert(state: TestedState.idle)
    }
  }
}
