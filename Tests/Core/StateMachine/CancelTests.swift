import StateMachineShared
import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class CancelTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: Cancel<MockSuperState, MockSuperEvent>!

  // MARK: - Methods
  func test_predicate_whenExpectedNewState_returnsTrue() async {
    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(whenNewState: Loaded.self)

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loading,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )

    // Then
    XCTAssertTrue(
      shouldCancel,
      "Expected predicate to return true when passed an expected state, but got \(shouldCancel) instead."
    )
  }

  func test_predicate_whenUnexpectedNewState_returnsFalse() async {
    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(whenNewState: Loaded.self)

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loading,
      TestedEvent.loadingFailed,
      TestedState.loading
    )

    // Then
    XCTAssertFalse(
      shouldCancel,
      "Expected predicate to return false when passed an expected state, but got \(shouldCancel) instead."
    )
  }

  func test_predicate_whenExpectedNewStateWithPredicate_returnsPredicateValue() async {
    let expectedNewState = Loaded(value: Int.random(in: 0...100))
    let expectedResult = Bool.random()
    let spy = SendableStorage<Loaded?>(value: nil)

    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(whenNewState: Loaded.self) { _, _, newState in
      spy.set(value: newState)
      return expectedResult
    }

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loading,
      TestedEvent.loadingSucceededWithValue1701,
      expectedNewState
    )

    // Then
    XCTAssertEqual(
      shouldCancel,
      expectedResult,
      """
      Expected predicate value to be \(expectedResult) when passed an expected new state with predicate,
      but got \(shouldCancel) instead.
      """
    )

    spy.assertEqual(expected: expectedNewState)
  }

  func test_predicate_whenExpectedEvent_returnsTrue() async {
    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(on: LoadingWasRequested.self)

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loading,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )

    // Then
    XCTAssertTrue(
      shouldCancel,
      "Expected predicate to return true when passed an expected event, but got \(shouldCancel) instead."
    )
  }

  func test_predicate_whenUnexpectedEvent_returnsFalse() async {
    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(on: LoadingWasRequested.self)

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loading,
      TestedEvent.loadingFailed,
      TestedState.loaded
    )

    // Then
    XCTAssertFalse(
      shouldCancel,
      "Expected predicate to return false when passed an unexpected event, but got \(shouldCancel) instead."
    )
  }

  func test_predicate_whenExpectedEventAndPredicateReturnsTrue_returnsTrue() async {
    let expectedEvent = LoadingWasRequested(id: 1701)
    let spy = SendableStorage<LoadingWasRequested?>(value: nil)

    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(on: LoadingWasRequested.self) { _, event, _ in
      spy.set(value: event)
      return true
    }

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loading,
      expectedEvent,
      TestedState.loaded
    )

    // Then
    XCTAssertTrue(
      shouldCancel,
      """
      Expected predicate to return true when passed expected event and predicate returns true,
      but got \(shouldCancel) instead.
      """
    )
    spy.assertEqual(expected: expectedEvent)
  }

  func test_predicate_whenExpectedEventAndPredicateReturnsFalse_returnsFalse() async {
    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(on: LoadingWasRequested.self) { _, _, _ in false }

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loading,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )

    // Then
    XCTAssertFalse(
      shouldCancel,
      """
      Expected predicate to return false when expected event and predicate returns false,
      """
    )
  }

  func test_predicate_whenExpectedCurrentStateExpectedEvent_returnsTrue() async {
    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(whencurrentState: Loading.self, on: LoadingWasRequested.self)

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loading,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )

    // Then
    XCTAssertTrue(
      shouldCancel,
      """
      Expected predicate to return true when expected current state and expected event
      but got \(shouldCancel) instead.
      """
    )
  }

  func test_predicate_whenUnexpectedCurrentStateExpectedEvent_returnsFalse() async {
    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(whencurrentState: Loading.self, on: LoadingWasRequested.self)

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loaded,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )

    // Then
    XCTAssertFalse(
      shouldCancel,
      """
      Expected predicate to return false when expected current state and expected event,
      but got \(shouldCancel) instead.
      """
    )
  }

  func test_predicate_whenExpectedCurrentStateUnexpectedEvent_returnsFalse() async {
    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(whencurrentState: Loading.self, on: LoadingWasRequested.self)

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loaded,
      TestedEvent.loadingFailed,
      TestedState.loaded
    )

    // Then
    XCTAssertFalse(
      shouldCancel,
      """
      Expected predicate to return false when expected current state and unexpected event,
      but got \(shouldCancel) instead.
      """
    )
  }

  func test_predicate_whenExpectedCurrentStateExpectedEventPredicateReturnsTrue_returnsTrue() async {
    let expectedState = Loading()
    let expectedEvent = LoadingWasRequested(id: 1701)

    let stateSpy = SendableStorage<Loading?>(value: nil)
    let eventSpy = SendableStorage<LoadingWasRequested?>(value: nil)

    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(
      whencurrentState: Loading.self,
      on: LoadingWasRequested.self
    ) { state, event, _ in
      stateSpy.set(value: state)
      eventSpy.set(value: event)
      return true
    }

    // When
    let shouldCancel = await sut.predicate(expectedState, expectedEvent, Loaded(value: 1701))

    // Then
    XCTAssertTrue(
      shouldCancel,
      """
      Expected predicate to return true when expected current state, expected event and predicate
      set to return true but got \(shouldCancel) instead.
      """
    )
    stateSpy.assertEqual(expected: expectedState)
    eventSpy.assertEqual(expected: expectedEvent)
  }

  func test_predicate_whenExpectedCurrentStateExpectedEventPredicateReturnsFalse_returnsFalse() async {
    // Given
    sut = Cancel<MockSuperState, MockSuperEvent>(
      whencurrentState: Loading.self,
      on: LoadingWasRequested.self
    ) { _, _, _ in false }

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loading,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )

    // Then
    XCTAssertFalse(
      shouldCancel,
      """
      Expected predicate to return false when expected current state, expected event and
      predicate set to return false, but got \(shouldCancel) instead.
      """
    )
  }

  func test_predicate_whenGivenPredicateReturnsTrue_returnsTrue() async {
    let expectedcurrentState = TestedState.loading
    let expectedEvent = TestedEvent.loadingRequestedWithValue1701
    let expectedNewState = TestedState.loaded

    let currentStateSpy = SendableStorage<Loading?>(value: nil)
    let eventSpy = SendableStorage<LoadingWasRequested?>(value: nil)
    let newStateSpy = SendableStorage<Loaded?>(value: nil)

    // Given
    sut = Cancel<MockSuperState, MockSuperEvent> { currentState, event, newState in
      currentStateSpy.set(value: currentState as? Loading)
      eventSpy.set(value: event as? LoadingWasRequested)
      newStateSpy.set(value: newState as? Loaded)
      return true
    }

    // When
    let shouldCancel = await sut.predicate(
      expectedcurrentState,
      expectedEvent,
      expectedNewState
    )

    // Then
    XCTAssertTrue(
      shouldCancel,
      """
      Expected predicate to return true when predicate set to return true,
      but got \(shouldCancel) instead.
      """
    )
    currentStateSpy.assertEqual(expected: expectedcurrentState)
    eventSpy.assertEqual(expected: expectedEvent)
    newStateSpy.assertEqual(expected: expectedNewState)
  }

  func test_predicate_whenGivenPredicateReturnsFalse_returnsFalse() async {
    // Given
    sut = Cancel<MockSuperState, MockSuperEvent> { _, _, _ in false }

    // When
    let shouldCancel = await sut.predicate(
      TestedState.loading,
      TestedEvent.loadingRequestedWithValue1701,
      TestedState.loaded
    )

    // Then
    XCTAssertFalse(
      shouldCancel,
      """
      Expected predicate to return false when predicate set to return false,
      but got \(shouldCancel) instead.
      """
    )
  }
}
