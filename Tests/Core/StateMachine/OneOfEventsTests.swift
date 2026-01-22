import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class OneOfEventsTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Types

  private enum Tested {
    static let eventSet = Set([
      ObjectIdentifier(LoadingWasRequested.self),
      ObjectIdentifier(LoadingHasSucceeded.self),
      ObjectIdentifier(LoadingHasFailed.self),
    ])
  }

  // MARK: - Properties

  var sut: OneOfEvents<MockSuperEvent>!

  // MARK: - Methods

  func test_init_withVariadicParameter_setsEvents() {
    // Given
    sut = OneOfEvents(
      LoadingWasRequested.self,
      LoadingHasSucceeded.self,
      LoadingHasFailed.self
    )

    // When
    // Then
    let expected = Tested.eventSet
    let received = sut.events
    XCTAssertEqual(received, expected, "Expected events to be \(expected), but got \(received) instead.")
  }

  func test_init_withSequence_setsEvents() {
    // Given
    sut = OneOfEvents([
      LoadingWasRequested.self,
      LoadingHasSucceeded.self,
      LoadingHasFailed.self,
    ])

    // When
    // Then
    let expected = Tested.eventSet
    let received = sut.events
    XCTAssertEqual(received, expected, "Expected events to be \(expected), but got \(received) instead.")
  }

  func test_contains_whenExpectedEventType_returnsTrue() {
    // Given
    sut = OneOfEvents(
      LoadingWasRequested.self,
      LoadingHasSucceeded.self,
      LoadingHasFailed.self
    )

    // When
    let received = sut.contains(event: LoadingWasRequested(id: 1701))

    // Then
    XCTAssertTrue(received, "Expected `contains` to return true when expected event type, but got \(received) instead.")
  }

  func test_contains_whenUnexpectedEventType_returnsFalse() {
    // Given
    sut = OneOfEvents(
      LoadingWasRequested.self,
      LoadingHasSucceeded.self,
      LoadingHasFailed.self
    )

    // When
    let received = sut.contains(event: ReloadingWasRequested(id: 1701))

    // Then
    XCTAssertFalse(
      received,
      "Expected `contains` to return false when unexpected event type, but got \(received) instead."
    )
  }
}
