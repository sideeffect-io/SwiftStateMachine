import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class AsyncUnicastChannelTests: XCTestCase, @unchecked Sendable {
  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = AsyncUnicastChannel<Int>()
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: AsyncUnicastChannel<Int>!

  // MARK: - Methods

  func test_send_whenNoIteration_buffersElementsUntilFinishedThenReturnsNil() async {
    let expected = [1, 2, 3, 4, 5]

    // Given an async unicast channel

    // When
    for element in expected {
      sut.send(element)
    }
    sut.finish()

    // Then
    var received = [Int]()
    var iterator = sut.makeAsyncIterator()
    while let element = await iterator.next() {
      received.append(element)
    }

    XCTAssertEqual(received, expected, "Expected to receive \(expected), but got \(received) instead.")

    let pastEnd = await iterator.next()
    XCTAssertNil(
      pastEnd,
      """
      Expected to receive `nil` when calling next on finished sequence's iterator,
      but got \(String(describing: pastEnd)) instead.
      """
    )
  }

  func test_send_whenSuspended_resumesIteration() {
    let iterationHasSuspended = expectation(description: "The iteration has suspended")
    let iterationHasFinished = expectation(description: "The iteration has finished")

    let expected = [1]

    // Given
    sut.onSuspended = {
      iterationHasSuspended.fulfill()
    } as (@Sendable () -> Void)

    Task {
      var received = [Int]()
      var iterator = sut.makeAsyncIterator()
      let element = await iterator.next()
      received.append(element!)

      XCTAssertEqual(received, expected, "Expected to receive \(expected), but got \(received) instead.")

      iterationHasFinished.fulfill()
    }

    wait(
      for: [
        iterationHasSuspended,
      ],
      timeout: 1.0
    )

    // When
    for element in expected {
      sut.send(element)
    }
    sut.finish()

    // Then
    wait(
      for: [
        iterationHasFinished,
      ],
      timeout: 1.0
    )
  }

  func test_next_whenPastEnd_returnsNil() async {
    // Given
    sut.send(1)
    sut.send(1)
    sut.send(1)
    sut.finish()

    var iterator = sut.makeAsyncIterator()
    _ = await iterator.next()
    _ = await iterator.next()
    _ = await iterator.next()

    // When
    let pastEnd = await iterator.next()

    // Then
    XCTAssertNil(
      pastEnd,
      """
      Expected to receive `nil` when calling next on finished sequence's iterator,
      but got \(String(describing: pastEnd)) instead.
      """
    )
  }

  func test_send_whenIterationSuspendedAndTaskCancelled_resumesIteration() {
    let iteration1HasSuspended = expectation(description: "The first iteration has suspended")
    let iteration1HasFinished = expectation(description: "The first iteration has finished")
    let iteration2HasFinished = expectation(description: "The second iteration has finished")

    // Given
    sut.onSuspended = {
      iteration1HasSuspended.fulfill()
    } as (@Sendable () -> Void)

    let task1 = Task {
      var received = [Int]()
      var iterator = sut.makeAsyncIterator()
      while let element = await iterator.next() {
        received.append(element)
      }
      XCTAssertTrue(received.isEmpty, "Expected to receive empty array, but got \(received) instead.")

      iteration1HasFinished.fulfill()
    }

    wait(
      for: [
        iteration1HasSuspended,
      ],
      timeout: 1.0
    )

    // When
    task1.cancel()

    wait(
      for: [
        iteration1HasFinished,
      ],
      timeout: 1.0
    )

    sut.send(1)
    sut.finish()

    Task {
      var received = [Int]()
      var iterator = sut.makeAsyncIterator()
      while let element = await iterator.next() {
        received.append(element)
      }

      let expected = [1]
      XCTAssertEqual(received, expected, "Expected to receive \(expected), but got \(received) instead.")

      iteration2HasFinished.fulfill()
    }

    // Then
    wait(for: [iteration2HasFinished], timeout: 1.0)
  }

  func test_droppingIteratorAfterEarlyBreak_allowsANewIterator() async {
    sut.send(1)

    do {
      var iterator = sut.makeAsyncIterator()
      let firstElement = await iterator.next()
      XCTAssertEqual(firstElement, 1)
      // The iterator is intentionally dropped before it receives `nil`.
    }

    sut.send(2)
    sut.finish()

    var secondIterator = sut.makeAsyncIterator()
    let secondElement = await secondIterator.next()
    let end = await secondIterator.next()
    XCTAssertEqual(secondElement, 2)
    XCTAssertNil(end)
  }

  func test_finish_whenIterationIsSuspended_finishesIteration() {
    let iterationHasSuspended = expectation(description: "The iteration has suspended")
    let iterationHasFinished = expectation(description: "The iteration has finished")

    // Given
    sut.onSuspended = {
      iterationHasSuspended.fulfill()
    } as (@Sendable () -> Void)

    Task {
      var received = [Int]()
      var iterator = sut.makeAsyncIterator()
      while let element = await iterator.next() {
        received.append(element)
      }
      XCTAssertTrue(received.isEmpty, "Expected to receive empty array, but got \(received) instead.")

      let pastEnd = await iterator.next()
      XCTAssertNil(
        pastEnd,
        """
        Expected to receive `nil` when calling next on finished sequence's iterator,
        but got \(String(describing: pastEnd)) instead.
        """
      )

      iterationHasFinished.fulfill()
    }

    wait(for: [iterationHasSuspended], timeout: 1.0)

    // When
    sut.finish()

    // Then
    wait(for: [iterationHasFinished], timeout: 1.0)
  }

  func test_queuedElements_whenElements_returnsElements() {
    let expectedQueuedElements = [Int.random(in: 1...1000), Int.random(in: 1...1000)]

    // Given
    for element in expectedQueuedElements {
      sut.send(element)
    }

    // When
    let receivedQueuedElements = sut.queuedElements.map { $0 }

    // Then
    XCTAssertEqual(
      receivedQueuedElements,
      expectedQueuedElements,
      """
      Expected to receive \(expectedQueuedElements),
      but got \(receivedQueuedElements) instead
      """
    )

    sut.finish()
  }

  func test_queuedElements_whenNoElements_returnsEmpty() async {
    // Given
    sut.send(1)
    sut.send(2)

    var iterator = sut.makeAsyncIterator()
    let _ = await iterator.next()
    let _ = await iterator.next()

    // When
    let receivedQueuedElements = sut.queuedElements

    // Them
    XCTAssertTrue(
      receivedQueuedElements.isEmpty,
      """
      Expected to have no queued elements,
      but got \(receivedQueuedElements) instead
      """
    )

    sut.finish()
  }

  func test_queuedElements_whenFinished_returnsEmpty() async {
    // Given
    sut.send(1)
    sut.send(2)
    sut.finish()

    for await _ in sut { }

    // When
    let receivedQueuedElements = sut.queuedElements

    // Them
    XCTAssertTrue(
      receivedQueuedElements.isEmpty,
      """
      Expected to have no queued elements,
      but got \(receivedQueuedElements) instead
      """
    )
  }

  func test_isFinishedWithoutElements_whenFinishedWithElements_returnsFalse() async {
    // Given
    sut.send(1)
    sut.send(2)
    sut.finish()

    // When
    let receivedIsFinishedWithoutElements = sut.isFinishedWithoutElements

    // Them
    XCTAssertFalse(
      receivedIsFinishedWithoutElements,
      """
      Expected receivedIsFinishedWithoutElements to be false,
      but got true instead
      """
    )
  }

  func test_isFinishedWithoutElements_whenFinishedWithoutElements_returnsTrue() async {
    // Given
    sut.send(1)
    sut.send(2)
    sut.finish()

    for await _ in sut { }

    // When
    let receivedIsFinishedWithoutElements = sut.isFinishedWithoutElements

    // Them
    XCTAssertTrue(
      receivedIsFinishedWithoutElements,
      """
      Expected receivedIsFinishedWithoutElements to be true,
      but got false instead
      """
    )
  }
}
