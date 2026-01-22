import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class OneOfEventsDslTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: OneOfEvents<MockSuperEvent>!

  // MARK: - Methods

  func test_init_withBuilder_setsEvents() {
    // Given
    sut = OneOfEvents {
      LoadingWasRequested.self
      LoadingHasSucceeded.self
      LoadingHasFailed.self
    }

    // Then
    let expected = Set([
      ObjectIdentifier(LoadingWasRequested.self),
      ObjectIdentifier(LoadingHasSucceeded.self),
      ObjectIdentifier(LoadingHasFailed.self),
    ])

    let sutEvents = sut.events
    XCTAssertEqual(
      sutEvents,
      expected,
      "Expected events to be \(expected), but got \(sutEvents) instead."
    )
  }
}
