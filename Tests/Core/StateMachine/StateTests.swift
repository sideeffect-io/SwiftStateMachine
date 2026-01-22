import StateMachineCore
import XCTest

// swiftlint:disable implicitly_unwrapped_optional

final class StateTests: XCTestCase {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = Idle()
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: (any State)!

  // MARK: - Methods

  func test_description_isStateTypeName() {
    // Given a state

    // When
    let received = "\(sut!)"

    // Then
    let expected = "\(type(of: sut!))"
    XCTAssertEqual(received, expected, "Expected the state type name to be \(expected), but got \(received) instead.")
  }
}
