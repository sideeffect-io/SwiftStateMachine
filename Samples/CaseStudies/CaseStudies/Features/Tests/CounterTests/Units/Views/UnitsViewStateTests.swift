import StateMachineCore
import XCTest
@testable import Counter

// swiftlint:disable implicitly_unwrapped_optional

final class UnitsUIStateTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
    expected = nil
    unitsState = nil
  }

  // MARK: - Types

  private enum TestedState {
    static let isIncreasing = UnitsState(
      value: 1,
      canDecrease: false,
      isIncreasing: true,
      isDecreasing: false
    )

    static let isDecreasing = UnitsState(
      value: 1,
      canDecrease: false,
      isIncreasing: false,
      isDecreasing: true
    )
  }

  // MARK: - Properties

  var sut: UnitsUIState!
  var expected: UnitsUIState!

  var unitsState: UnitsState!

  // MARK: - Methods

  func test_init_withIsIncreasingUnitsState_returnsExpectedUIState() {
    // Given
    unitsState = TestedState.isIncreasing
    sut = UnitsUIState(unitsState: unitsState, color: .green)

    // When
    expected = makeUIState(state: unitsState)

    // Then
    XCTAssertEqual(
      expected,
      sut,
      """
      Expected the `UnitsUIState` initialized from an `isIncreasing` `unitsState` to be \(String(describing: expected)),
      but got \(String(describing: sut)) instead.
      """
    )
  }

  func test_init_withIsDecreasingUnitsState_returnsExpectedUIState() {
    // Given
    unitsState = TestedState.isDecreasing
    sut = UnitsUIState(unitsState: unitsState, color: .red)

    // When
    expected = makeUIState(state: unitsState)

    // Then
    XCTAssertEqual(
      expected,
      sut,
      """
      Expected the `UnitsUIState` initialized from an `isDecreasing` `unitsState` to be \(String(describing: expected)),
      but got \(String(describing: sut)) instead.
      """
    )
  }
}
