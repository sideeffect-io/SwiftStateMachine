import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class OutputTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: Output<MockSuperState, MockSuperEvent>!

  // MARK: - Methods
  func test_init_withPriority_setsPriority() throws {
    let expectedPriority = TaskPriority.high

    // Given
    sut = Output<MockSuperState, MockSuperEvent>(priority: .high, sideEffect: { nil })

    // when
    let receivedPriority = try XCTUnwrap(sut.priority)

    // Then
    XCTAssertEqual(
      receivedPriority,
      expectedPriority,
      "Expected priority to be \(expectedPriority), but got \(receivedPriority) instead."
    )
  }

  func test_init_withSequence_setsSideEffect() async throws {
    let expectedNextEvent = TestedEvent.loadingRequestedWithValue1701

    // Given
    sut = Output<MockSuperState, MockSuperEvent> {
      AsyncNonThrowingSequence { expectedNextEvent }
    }

    // when
    let receivedSequence = await sut.sideEffect()
    var receivedNextEvent = [any Event<MockSuperEvent>]()
    for await element in receivedSequence {
      receivedNextEvent.append(element)
    }

    // Then
    let receivedNextEventTyped = receivedNextEvent as? [LoadingWasRequested]
    XCTAssertEqual(
      receivedNextEventTyped,
      [expectedNextEvent],
      """
      Expected next event array to be \(String(describing: [expectedNextEvent])),
      but got \(String(describing: receivedNextEventTyped)) instead.
      """
    )
  }

  func test_init_withSequence_setsSideEffectAndCancellationPolicy() async throws {
    // Given
    sut = Output<MockSuperState, MockSuperEvent>(
      sideEffect: { AsyncNonThrowingSequence<any Event<MockSuperEvent>> { nil } },
      cancellationPolicy: Cancel(on: LoadingWasRequested.self)
    )

    // when
    let receivedCancel = sut.cancellationPolicy

    // Then
    let cancel = try XCTUnwrap(receivedCancel)
    let shouldCancel = await cancel.predicate(
      TestedState.loading,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )
    XCTAssertTrue(
      shouldCancel,
      """
      Expected predicate to return true when condition set in initializer's cancellation policy realized
      but got \(shouldCancel) instead.
      """
    )
  }

  func test_init_withSequenceAndClosure_setsSideEffectAndCancellationPolicy() async throws {
    let expectedNextEvent = TestedEvent.loadingRequestedWithValue1701

    // Given
    sut = Output<MockSuperState, MockSuperEvent>(
      sideEffect: { AsyncNonThrowingSequence { expectedNextEvent } },
      cancellationPolicy: Cancel(on: LoadingWasRequested.self)
    )

    // when
    let receivedCancel = sut.cancellationPolicy
    let receivedSequence = await sut.sideEffect()
    var receivedNextEvent = [any Event<MockSuperEvent>]()
    for await element in receivedSequence {
      receivedNextEvent.append(element)
    }

    // Then
    let cancel = try XCTUnwrap(receivedCancel)
    let shouldCancel = await cancel.predicate(
      TestedState.loading,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )

    XCTAssertTrue(
      shouldCancel,
      """
      Expected predicate to return true when condition set in initializer's cancellation policy realized,
      but got \(shouldCancel) instead.
      """
    )

    XCTAssertEqual(receivedNextEvent as? [LoadingWasRequested], [expectedNextEvent])
  }

  func test_init_withNilEvent_setsSideEffectWithEmptyAsyncSequence() async throws {
    // Given
    sut = Output<MockSuperState, MockSuperEvent> {
      nil
    }

    // When
    let receivedSequence = await sut.sideEffect()
    var receivedNextEvent = [any Event<MockSuperEvent>]()
    for await element in receivedSequence {
      receivedNextEvent.append(element)
    }

    // Then
    XCTAssertTrue(
      receivedNextEvent.isEmpty,
      "Expected received sequence to be empty when `nil` event, but got \(receivedNextEvent) instead."
    )
  }

  func test_init_withNonNilEvent_setsSideEffectWithOneElementAsyncSequence() async throws {
    let expectedNextEvent = TestedEvent.loadingSucceededWithValue1702

    // Given
    sut = Output<MockSuperState, MockSuperEvent> {
      expectedNextEvent
    }

    // When
    let receivedSequence = await sut.sideEffect()
    var receivedNextEvent = [any Event<MockSuperEvent>]()
    for await element in receivedSequence {
      receivedNextEvent.append(element)
    }

    // Then
    let receivedNextEventTyped = receivedNextEvent as? [LoadingHasSucceeded]
    XCTAssertEqual(
      receivedNextEventTyped,
      [expectedNextEvent],
      """
      Expected async sequence to publish \(String(describing: [expectedNextEvent]))
      but received \(String(describing: receivedNextEventTyped)) instead.
      """
    )
  }

  func test_init_withSideEffectAndCancellationPolicyWithEvent_setsSideEffectAndCancellationPolicyWithEvent() async throws {
    // Given
    sut = Output<MockSuperState, MockSuperEvent>(
      sideEffect: { TestedEvent.loadingSucceededWithValue1701 },
      cancellationPolicy: Cancel(on: LoadingWasRequested.self)
    )

    // when
    let receivedCancel = sut.cancellationPolicy

    // Then
    let cancel = try XCTUnwrap(receivedCancel)
    let shouldCancel = await cancel.predicate(
      TestedState.loading,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )
    XCTAssertTrue(
      shouldCancel,
      """
      Expected predicate to return true when condition set in initializer's cancellation policy realized,
      but got \(shouldCancel) instead.
      """
    )
  }

  func test_init_withSideEffectAndCancellationPolicyWithEventAndClosure_setsSideEffectAndCancellationPolicyWithClosure(
  ) async throws {
    let expectedNextEvent = TestedEvent.loadingSucceededWithValue1702

    // Given
    sut = Output<MockSuperState, MockSuperEvent>(
      sideEffect: { expectedNextEvent },
      cancellationPolicy: Cancel(on: LoadingWasRequested.self)
    )

    // when
    let receivedSequence = await sut.sideEffect()
    var receivedNextEvent = [any Event<MockSuperEvent>]()
    for await element in receivedSequence {
      receivedNextEvent.append(element)
    }
    let receivedCancel = sut.cancellationPolicy

    // Then
    let cancel = try XCTUnwrap(receivedCancel)
    let shouldCancel = await cancel.predicate(
      TestedState.loading,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )
    XCTAssertTrue(
      shouldCancel,
      """
      Expected predicate to return true when condition set in initializer's cancellation policy realized,
      but got \(shouldCancel) instead.
      """
    )
    let receivedNextEventTyped = receivedNextEvent as? [LoadingHasSucceeded]
    XCTAssertEqual(
      receivedNextEventTyped,
      [expectedNextEvent],
      """
      Expected async sequence to publish \(String(describing: [expectedNextEvent]))
      but received \(String(describing: receivedNextEventTyped)) instead.
      """
    )
  }

  func test_cancellationPolicyModifier_setsSideEffectAndCancellationPolicy() async throws {
    // Given
    sut = Output<MockSuperState, MockSuperEvent>(sideEffect: { TestedEvent.loadingSucceededWithValue1701 })
      .cancellationPolicy(cancel: Cancel(on: LoadingWasRequested.self))

    // when
    let receivedCancel = sut.cancellationPolicy

    // Then
    let cancel = try XCTUnwrap(receivedCancel)
    let shouldCancel = await cancel.predicate(
      TestedState.loading,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )
    XCTAssertTrue(
      shouldCancel,
      """
      Expected predicate to return true when condition set in initializer's cancellation policy modifier realized,
      but got \(shouldCancel) instead.
      """
    )
  }
}
