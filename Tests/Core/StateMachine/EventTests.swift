import StateMachineCore
import XCTest

// swiftlint:disable implicitly_unwrapped_optional

final class EventTests: XCTestCase {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = LoadingHasSucceeded(value: 1701)
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: (any Event)!

  // MARK: - Methods

  func test_description_isEventTypeName() {
    // Given an event

    // When
    let received = "\(sut!)"

    // Then
    let expected = "\(type(of: sut!))"
    XCTAssertEqual(received, expected, "Expected the description to be \(expected), but got \(received) instead.")
  }
}
