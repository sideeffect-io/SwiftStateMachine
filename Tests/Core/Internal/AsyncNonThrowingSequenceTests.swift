import StateMachineShared
import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class AsyncNonThrowingSequenceTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: AsyncNonThrowingSequence<any Event<MockSuperEvent>>!

  // MARK: - Methods

  func test_await_whenBaseDoesNotThrow_deliversSameEvents() async {
    let expected: [any Event<MockSuperEvent>] = [
      TestedEvent.loadingRequestedWithValue1701,
      TestedEvent.loadingSucceededWithValue1701,
      TestedEvent.loadingFailed,
    ]

    // Given
    let base = AsyncStream { continuation in
      continuation.yield(expected[0])
      continuation.yield(expected[1])
      continuation.yield(expected[2])
      continuation.finish()
    }

    // When
    sut = base.eraseToAsyncNonThrowingSequence()

    var received = [any Event<MockSuperEvent>]()
    for await element in sut {
      received.append(element)
    }

    // Then
    let receivedNumberOfElements = received.count
    let expectedNumberOfElements = 3
    XCTAssertEqual(
      receivedNumberOfElements,
      expectedNumberOfElements,
      """
      Expected to receive \(expectedNumberOfElements) elements,
      but got \(receivedNumberOfElements) instead.
      """
    )
    XCTAssertEqual(anyLhs: received[0], anyRhs: expected[0])
    XCTAssertEqual(anyLhs: received[1], anyRhs: expected[1])
    XCTAssertEqual(anyLhs: received[2], anyRhs: expected[2])
  }

  func test_await_whenBaseThrows_deliversSameElementsAndFinishes() async {
    let expected: [any Event<MockSuperEvent>] = [
      TestedEvent.loadingRequestedWithValue1701,
      TestedEvent.loadingSucceededWithValue1701,
      TestedEvent.loadingFailed,
    ]
    let expectedFailure = MockError()

    // Given
    let base = AsyncThrowingStream { continuation in
      continuation.yield(expected[0])
      continuation.yield(expected[1])
      continuation.yield(expected[2])
      continuation.yield(with: .failure(expectedFailure))
    }

    // When
    sut = base.eraseToAsyncNonThrowingSequence()

    var received = [any Event<MockSuperEvent>]()
    for await element in sut {
      received.append(element)
    }

    // Then
    let receivedNumberOfElements = received.count
    let expectedNumberOfElements = 3
    XCTAssertEqual(
      receivedNumberOfElements,
      expectedNumberOfElements,
      """
      Expected to receive \(expectedNumberOfElements) elements,
      but got \(receivedNumberOfElements) instead.
      """
    )
    XCTAssertEqual(anyLhs: received[0], anyRhs: expected[0])
    XCTAssertEqual(anyLhs: received[1], anyRhs: expected[1])
    XCTAssertEqual(anyLhs: received[2], anyRhs: expected[2])
  }

  func test_await_whenClosureReturnsEvent_deliversElement() async {
    let expected = LoadingWasRequested(id: 1701)

    // Given
    sut = AsyncNonThrowingSequence(factory: { expected })

    // When
    var received = [any Event<MockSuperEvent>]()
    for await element in sut {
      received.append(element)
    }

    // Then
    XCTAssertEqual(anyLhs: received[0], anyRhs: expected)
  }

  func test_await_whenClosureReturnsNil_finishes() async {
    // Given
    sut = AsyncNonThrowingSequence<any Event<MockSuperEvent>>(factory: { nil })

    // When
    var received = [any Event<MockSuperEvent>]()
    for await element in sut {
      received.append(element)
    }

    // Then
    XCTAssertTrue(received.isEmpty, "Expected received array to be empty, but got \(received) instead.")
  }
}
