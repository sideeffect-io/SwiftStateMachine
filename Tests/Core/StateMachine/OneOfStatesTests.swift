import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class OneOfStatesTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Types

  private enum Tested {
    static let stateSet = Set([
      ObjectIdentifier(Loading.self),
      ObjectIdentifier(Loaded.self),
      ObjectIdentifier(Failed.self),
    ])
  }

  // MARK: - Properties

  var sut: OneOfStates<MockSuperEvent>!

  // MARK: - Methods

  func test_init_withVariadicParameter_setsStates() {
    // Given
    let sut = OneOfStates(
      Loading.self,
      Loaded.self,
      Failed.self
    )

    // When
    // Then
    let expected = Tested.stateSet
    let received = sut.states
    XCTAssertEqual(received, expected, "Expected states to be \(expected), but got \(received) instead.")
  }

  func test_init_withSequence_returnStates() {
    // Given
    let sut = OneOfStates([
      Loading.self,
      Loaded.self,
      Failed.self,
    ])

    // When
    // Then
    let expected = Tested.stateSet
    let received = sut.states
    XCTAssertEqual(received, expected, "Expected states to be \(expected), but got \(received) instead.")
  }

  func test_init_withDuplicateTypes_deduplicatesWithoutTrapping() {
    let sut = OneOfStates([
      Loading.self,
      Loading.self,
      Loaded.self,
    ])

    XCTAssertEqual(
      sut.states,
      Set([ObjectIdentifier(Loading.self), ObjectIdentifier(Loaded.self)])
    )
  }

  func test_contains_whenExpectedStateType_returnsTrue() {
    // Given
    let sut = OneOfStates([
      Loading.self,
      Loaded.self,
      Failed.self,
    ])

    // When
    let received = sut.contains(state: Loading())

    // Then
    XCTAssertTrue(received, "Expected `contains` to return true when expected state type, but got \(received) instead.")
  }

  func test_contains_whenUnexpectedStateType_returnsFalse() {
    // Given
    let sut = OneOfStates([
      Loading.self,
      Loaded.self,
      Failed.self,
    ])

    // When
    let received = sut.contains(state: Idle())

    // Then
    XCTAssertFalse(
      received,
      "Expected `contains` to return false when expected state type, but got \(received) instead."
    )
  }
}
