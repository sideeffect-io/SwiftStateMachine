import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class OneOfStatesDslTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: OneOfStates<MockSuperState>!

  // MARK: - Methods

  func test_init_withBuilder_setsStates() {
    // Given
    sut = OneOfStates {
      Loading.self
      Loaded.self
      Failed.self
    }

    // Then
    let sutStates = sut.states
    let expected = Set([
      ObjectIdentifier(Loading.self),
      ObjectIdentifier(Loaded.self),
      ObjectIdentifier(Failed.self),
    ])

    XCTAssertEqual(
      sutStates,
      expected,
      "Expected states to be \(expected), but got \(sutStates) instead."
    )
  }
}
