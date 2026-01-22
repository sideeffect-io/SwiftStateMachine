import StateMachineCore
import XCTest
@testable import Analysis

// swiftlint:disable implicitly_unwrapped_optional

final class StatesTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
    expected = nil
    received = nil
  }

  // MARK: - Types

  private enum TestedState {
    static let idle = AnalysisState(
      message: "Ready to start a new analysis",
      canMakeNewAnalysis: true,
      canResetAnalysis: false
    )

    static let performing = AnalysisState(
      message: "Analysis in progress (id = \(identifier))",
      canMakeNewAnalysis: false,
      canResetAnalysis: true
    )

    static let performed = AnalysisState(
      message: "Analysis is finished (id = \(identifier))",
      canMakeNewAnalysis: false,
      canResetAnalysis: true
    )
  }

  // MARK: - Properties

  static let identifier = Int.random(in: 0...100)

  var sut: (any StateMachineCore.State)!
  var expected: AnalysisState!
  var received: AnalysisState!

  // MARK: - Methods

  func test_idleState_derivesExpectedSuperState() {
    // Given
    sut = AnalysisIsIdle()

    // When
    received = sut.superState as? AnalysisState

    // Then
    expected = TestedState.idle
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the super state derived from the idle state to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }

  func test_performingState_derivesExpectedSuperState() {
    // Given
    sut = AnalysisIsInProgress(identifier: Self.identifier)

    // When
    received = sut.superState as? AnalysisState

    // Then
    expected = TestedState.performing
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the super state derived from the performing state to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }

  func test_performedState_derivesExpectedSuperState() {
    // Given
    sut = AnalysisIsDone(identifier: Self.identifier)

    // When
    received = sut.superState as? AnalysisState

    // Then
    expected = TestedState.performed
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the super state derived from the performed state to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }
}
