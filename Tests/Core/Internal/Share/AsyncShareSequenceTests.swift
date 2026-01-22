import os
import XCTest
@testable import StateMachineCore

// MARK: - AsyncSpySequence

// swiftlint:disable implicitly_unwrapped_optional

struct AsyncSpySequence<Base: Sequence>: AsyncSequence, Sendable
  where Base: Sendable, Base.Element: Sendable
{
  typealias Element = Base.Element
  typealias AsyncIterator = Iterator

  let base: Base
  let safeNumberOfCallsToNext = OSAllocatedUnfairLock<Int>(initialState: 0)

  init(base: Base) {
    self.base = base
  }

  var numberOfCallsToNext: Int {
    safeNumberOfCallsToNext.withLock { $0 }
  }

  func makeAsyncIterator() -> Iterator {
    Iterator(
      baseIterator: base.makeIterator(),
      onNext: { safeNumberOfCallsToNext.withLock { $0 += 1 } }
    )
  }

  struct Iterator: AsyncIteratorProtocol {
    var baseIterator: Base.Iterator
    let onNext: () -> Void

    mutating func next() async throws -> Element? {
      onNext()
      return baseIterator.next()
    }
  }
}

// MARK: - AsyncShareSequenceTests

final class AsyncShareSequenceTests: XCTestCase, @unchecked Sendable {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()
    baseAsyncSequence = AsyncSpySequence(base: baseSequence)
  }

  override func tearDown() {
    super.tearDown()
    baseAsyncSequence = nil
    sut = nil
  }

  // MARK: - Properties

  let baseSequence = (0..<10).map { $0 }
  var baseAsyncSequence: AsyncSpySequence<[Int]>!
  var sut: AsyncShareSequence<AsyncSpySequence<[Int]>>!

  // MARK: - Methods

  func test_share_whenIteratedInTwoTasks_baseNextIsCalledTheExpectedNumberOfTimes() async {
    // Given
    let expectedNumerOfCallsToNext = baseSequence.count + 1 // + 1 is for the last call when returning nil

    // When
    sut = baseAsyncSequence.share(replayCount: .unbounded)

    await withTaskGroup(of: Void.self) { group in
      group.addTask {
        for await _ in self.sut { }
      }
      group.addTask {
        for await _ in self.sut { }
      }
    }

    // Then
    let receivedNumberOfCallsToNext = baseAsyncSequence.numberOfCallsToNext

    XCTAssertEqual(
      receivedNumberOfCallsToNext,
      expectedNumerOfCallsToNext,
      """
      Expected to receive a number of calls to next of \(expectedNumerOfCallsToNext),
      but got \(receivedNumberOfCallsToNext) instead
      """
    )
  }

  func test_share_whenIteratedInThreeTasks_elementsAreShared() async {
    // Given

    // When
    sut = baseAsyncSequence.share(replayCount: .unbounded)

    let results = await withTaskGroup(of: [Int].self) { group in
      group.addTask {
        var received = [Int]()
        for await element in self.sut {
          received.append(element)
        }
        return received
      }
      group.addTask {
        var received = [Int]()
        for await element in self.sut {
          received.append(element)
        }
        return received
      }
      group.addTask {
        var received = [Int]()
        for await element in self.sut {
          received.append(element)
        }
        return received
      }

      let receivedArray1 = await group.next()
      let receivedArray2 = await group.next()
      let receivedArray3 = await group.next()

      return [receivedArray1, receivedArray2, receivedArray3]
    }

    // Then
    XCTAssertEqual(results[0], baseSequence)
    XCTAssertEqual(results[0], results[1])
    XCTAssertEqual(results[1], results[2])
  }

  func test_share_whenReplayIsUnbounded_elementsAreAllReplayed() async {
    // Given
    let expectedNumerOfCallsToNext = baseSequence.count + 1 // + 1 is for the last call when returning nil

    // When
    sut = baseAsyncSequence.share(replayCount: .unbounded)

    // the shared sequence is iterated over a first time
    for await _ in sut { }

    var receivedNumberOfCallsToNext = baseAsyncSequence.numberOfCallsToNext

    XCTAssertEqual(
      receivedNumberOfCallsToNext,
      expectedNumerOfCallsToNext,
      """
      Expected to receive a number of calls to next of \(expectedNumerOfCallsToNext),
      but got \(receivedNumberOfCallsToNext) instead
      """
    )

    // the shared sequence is iterated over a second time
    var receivedElements = [Int]()
    for await element in sut {
      receivedElements.append(element)
    }

    receivedNumberOfCallsToNext = baseAsyncSequence.numberOfCallsToNext

    // Then
    XCTAssertEqual(
      receivedNumberOfCallsToNext,
      expectedNumerOfCallsToNext,
      """
      Expected to receive a number of calls to next of \(expectedNumerOfCallsToNext),
      but got \(receivedNumberOfCallsToNext) instead
      """
    )

    XCTAssertEqual(
      receivedElements,
      baseSequence,
      """
      Expected to receive the elements \(baseSequence),
      but got \(receivedElements) instead
      """
    )
  }

  func test_share_whenReplayIsMaxZero_noElementsAreReplayed() async {
    let expectedNumerOfCallsToNext = baseSequence.count + 1 // + 1 is for the last call when returning nil

    // Given

    // When
    sut = baseAsyncSequence.share(replayCount: .max(count: 0))

    // the shared sequence is iterated over a first time
    for await _ in sut { }

    var receivedNumberOfCallsToNext = baseAsyncSequence.numberOfCallsToNext

    XCTAssertEqual(
      receivedNumberOfCallsToNext,
      expectedNumerOfCallsToNext,
      """
      Expected to receive a number of calls to next of \(expectedNumerOfCallsToNext),
      but got \(receivedNumberOfCallsToNext) instead
      """
    )

    // the shared sequence is iterated over a second time
    var receivedElements = [Int]()
    for await element in sut {
      receivedElements.append(element)
    }

    receivedNumberOfCallsToNext = baseAsyncSequence.numberOfCallsToNext

    // Then
    XCTAssertEqual(
      receivedNumberOfCallsToNext,
      expectedNumerOfCallsToNext,
      """
      Expected to receive a number of calls to next of \(expectedNumerOfCallsToNext),
      but got \(receivedNumberOfCallsToNext) instead
      """
    )

    XCTAssertTrue(
      receivedElements.isEmpty,
      """
      Expected to receive 0 element in the second iteration,
      but got \(receivedElements) instead
      """
    )
  }

  func test_share_whenReplayIsFive_fiveLastElementsAreReplayed() async {
    let expectedNumerOfCallsToNext = baseSequence.count + 1 // + 1 is for the last call when returning nil

    // Given

    // When
    sut = baseAsyncSequence.share(replayCount: .max(count: 5))

    // the shared sequence is iterated over a first time
    for await _ in sut { }

    var receivedNumberOfCallsToNext = baseAsyncSequence.numberOfCallsToNext

    XCTAssertEqual(
      receivedNumberOfCallsToNext,
      expectedNumerOfCallsToNext,
      """
      Expected to receive a number of calls to next of \(expectedNumerOfCallsToNext),
      but got \(receivedNumberOfCallsToNext) instead
      """
    )

    // the shared sequence is iterated over a second time
    var receivedElements = [Int]()
    for await element in sut {
      receivedElements.append(element)
    }

    receivedNumberOfCallsToNext = baseAsyncSequence.numberOfCallsToNext

    // Then
    XCTAssertEqual(
      receivedNumberOfCallsToNext,
      expectedNumerOfCallsToNext,
      """
      Expected to receive a number of calls to next of \(expectedNumerOfCallsToNext),
      but got \(receivedNumberOfCallsToNext) instead
      """
    )

    XCTAssertEqual(
      receivedElements,
      baseSequence.suffix(5),
      """
      Expected to receive the elements \(baseSequence),
      but got \(receivedElements) instead
      """
    )
  }

  func test_share_whenClientIsCanceledBeforeNext_endsIteration() async {
    let expectedNumerOfCallsToNext = baseSequence.count + 1 // + 1 is for the last call when returning nil

    let nextIsCalledExpectation = expectation(description: "Task has called next a first time")
    let taskWasCanceledExpectation = expectation(description: "Task was canceled")
    let iterationIsEndedExpectation = expectation(description: "Task iteration is over")

    sut = baseAsyncSequence.share(replayCount: .unbounded)

    let task = Task<Void, Never> {
      for await _ in self.sut {
        nextIsCalledExpectation.fulfill()
        await fulfillment(of: [taskWasCanceledExpectation], timeout: 1.0)
      }
      iterationIsEndedExpectation.fulfill()
    }

    await fulfillment(of: [nextIsCalledExpectation], timeout: 1.0)

    // When
    task.cancel()

    taskWasCanceledExpectation.fulfill()

    // Then
    await fulfillment(of: [iterationIsEndedExpectation], timeout: 1.0)

    var receivedElements = [Int]()
    for await element in sut {
      receivedElements.append(element)
    }

    let receivedNumberOfCallsToNext = baseAsyncSequence.numberOfCallsToNext

    // Then
    XCTAssertEqual(
      receivedNumberOfCallsToNext,
      expectedNumerOfCallsToNext,
      """
      Expected to receive a number of calls to next of \(expectedNumerOfCallsToNext),
      but got \(receivedNumberOfCallsToNext) instead
      """
    )

    XCTAssertEqual(
      receivedElements,
      baseSequence,
      """
      Expected to receive the elements \(baseSequence),
      but got \(receivedElements) instead
      """
    )
  }

  func test_share_whenClientIsCanceledDuringNext_endsIteration() async {
    let baseIsSuspendedExpectation = expectation(description: "The base async sequence is suspended")
    let iterationIsEndedExpectation = expectation(description: "Task iteration is over")

    let expectedElement = Int.random(in: 1...1000)

    let baseAsyncSequence = AsyncUnicastChannel<Int>()
    baseAsyncSequence.onSuspended = {
      baseIsSuspendedExpectation.fulfill()
    }

    let shared = baseAsyncSequence.share(replayCount: .unbounded)

    let task = Task<Void, Never> {
      for await _ in shared { }
      iterationIsEndedExpectation.fulfill()
    }

    await fulfillment(of: [baseIsSuspendedExpectation], timeout: 1.0)

    // When
    task.cancel()

    // Then
    await fulfillment(of: [iterationIsEndedExpectation], timeout: 1.0)

    baseAsyncSequence.send(expectedElement)
    baseAsyncSequence.finish()

    var receivedElements = [Int]()
    for await element in shared {
      receivedElements.append(element)
    }

    XCTAssertEqual(
      receivedElements,
      [expectedElement],
      """
      Expected to receive the elements \(baseSequence),
      but got \(receivedElements) instead
      """
    )
  }
}
