import StateMachineCore
import XCTest
@testable import Counter

// swiftlint:disable implicitly_unwrapped_optional

final class UnitsStatesTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
    expected = nil
    received = nil
  }

  // MARK: - Types

  private enum TestedState {
    static let fixedStrictlyPositiveValue = UnitsState(
      value: 1,
      canDecrease: true,
      isIncreasing: false,
      isDecreasing: false
    )

    static let fixedZeroValue = UnitsState(
      value: 0,
      canDecrease: false,
      isIncreasing: false,
      isDecreasing: false
    )

    static let increasingStrictlyPositiveValue = UnitsState(
      value: 5,
      canDecrease: true,
      isIncreasing: true,
      isDecreasing: false
    )

    static let decreasingStrictlyPositiveValue = UnitsState(
      value: 1,
      canDecrease: true,
      isIncreasing: false,
      isDecreasing: true
    )

    static let decreasingZeroValue = UnitsState(
      value: 0,
      canDecrease: false,
      isIncreasing: false,
      isDecreasing: true
    )
  }

  // MARK: - Properties

  var sut: (any StateMachineCore.State)!
  var expected: UnitsState!
  var received: UnitsState!

  // MARK: - Methods

  func test_fixedState_withGreaterThan0Value_derivesExpectedSuperState() {
    // Given
    sut = ValueIsFixed(value: 1)

    // When
    received = sut.superState as? UnitsState

    // Then
    expected = TestedState.fixedStrictlyPositiveValue
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the super state derived from a fixed state with a value greater than 0
      to be \(String(describing: expected)), but got \(String(describing: received)) instead.
      """
    )
  }

  func test_fixedState_with0Value_derivesExpectedSuperState() {
    // Given
    sut = ValueIsFixed(value: 0)

    // When
    received = sut.superState as? UnitsState

    // Then
    expected = TestedState.fixedZeroValue
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the super state derived from a fixed state with a value of 0 to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }

  func test_increasingState_derivesExpectedSuperState() {
    // Given
    sut = ValueIsIncreasing(value: 5)

    // When
    received = sut.superState as? UnitsState

    // Then
    expected = TestedState.increasingStrictlyPositiveValue
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the super state derived from an increasing state to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }

  func test_decreasingState_withGreaterThan0Value_derivesExpectedSuperState() {
    // Given
    sut = ValueIsDecreasing(value: 1)

    // When
    received = sut.superState as? UnitsState

    // Then
    expected = TestedState.decreasingStrictlyPositiveValue
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the super state derived from a decreasing state with a value greater than 0
      to be \(String(describing: expected)), but got \(String(describing: received)) instead.
      """
    )
  }

  func test_decreasingState_with0Value_derivesExpectedSuperState() {
    // Given
    sut = ValueIsDecreasing(value: 0)

    // When
    received = sut.superState as? UnitsState

    // Then
    expected = TestedState.decreasingZeroValue
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the super state derived from a fixed state with a value of 0 to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }
}
