import StateMachineShared
import XCTest
@testable import StateMachineCore

// MARK: - OnTests

// swiftlint:disable implicitly_unwrapped_optional

final class OnTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
    receivedMealyTransition = nil
  }

  // MARK: - Types

  private enum Tested {
    static let assertableMealyTransition = MealyTransition.makeAssertable(
      transitionTo: Loading(),
      emit: LoadingHasSucceeded(value: 1)
    )

    static let expectedStateInGuard = TestedState.idle
    static let expectedEventInGuard = TestedEvent.loadingRequestedWithValue1701
  }

  // MARK: - Properties

  var sut: On<Idle, MockSuperState, MockSuperEvent>!
  var receivedMealyTransition: MealyTransition<MockSuperState, MockSuperEvent>?
}

// MARK: tests when returning MealyTransition

extension OnTests {
  func test_init_withTransitionAndOutput_setsMealyTransition() async {
    // Given
    sut = On<Idle, MockSuperState, MockSuperEvent>(event: LoadingWasRequested.self) { _, _ in
      Tested.assertableMealyTransition.transition
      Tested.assertableMealyTransition.output
    }

    // When
    receivedMealyTransition = await sut.mealyTransition(TestedState.idle, TestedEvent.loadingRequestedWithValue1701)

    // Then
    let received = sut.oneOfEvents
    let expected = OneOfEvents(LoadingWasRequested.self)
    XCTAssertEqual(
      expected,
      received,
      "Expected events to be \(expected) but got \(received) instead."
    )

    await XCTAssert(received: receivedMealyTransition, isFrom: Tested.assertableMealyTransition)
  }

  func test_mealyTransition_whenSetWithTransitionAndOutputInitializerAndWrongEventTypePassed_returnsNil() async {
    // Given
    sut = On<Idle, MockSuperState, MockSuperEvent>(event: LoadingWasRequested.self) { _, _ in
      Transition(state: TestedState.loading)
      Output(sideEffect: { TestedEvent.loadingSucceededWithValue1701 })
    }

    // When
    receivedMealyTransition = await sut.mealyTransition(TestedState.idle, TestedEvent.loadingSucceededWithValue1701)

    // Then
    XCTAssertNil(
      receivedMealyTransition,
      """
      Expected mealy transition to be `nil` when wrong event type passed,
      but got \(String(describing: receivedMealyTransition)) instead.
      """
    )
  }

  func test_init_withOneOfEventsTransitionAndOutput_setsMealyTransition() async {
    // Given
    sut = On<Idle, MockSuperState, MockSuperEvent> {
      LoadingWasRequested.self
      ReloadingWasRequested.self
    } transition: { _, _ in
      Tested.assertableMealyTransition.transition
      Tested.assertableMealyTransition.output
    }

    // When
    receivedMealyTransition = await sut.mealyTransition(TestedState.idle, TestedEvent.loadingRequestedWithValue1701)

    // Then
    let expected = OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
    let received = sut.oneOfEvents
    XCTAssertEqual(
      expected,
      received,
      "Expected events to be \(expected) but got \(received) instead."
    )

    await XCTAssert(received: receivedMealyTransition, isFrom: Tested.assertableMealyTransition)
  }

  func test_init_withEventsTransitionAndOutput_setsMealyTransition() async {
    // Given
    sut = On<Idle, MockSuperState, MockSuperEvent>(
      events:
      LoadingWasRequested.self,
      ReloadingWasRequested.self
    ) { _, _ in
      Tested.assertableMealyTransition.transition
      Tested.assertableMealyTransition.output
    }

    // When
    receivedMealyTransition = await sut.mealyTransition(TestedState.idle, TestedEvent.loadingRequestedWithValue1701)

    // Then
    let expected = OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
    let received = sut.oneOfEvents
    XCTAssertEqual(
      expected,
      received,
      "Expected events to be \(expected) but got \(received) instead."
    )

    await XCTAssert(received: receivedMealyTransition, isFrom: Tested.assertableMealyTransition)
  }

  func test_mealyTransition_whenSetWithOneOfEventsTransitionAndOutputInitializerAndWrongEventTypePassed_returnsNil(
  ) async {
    // Given
    sut = On<Idle, MockSuperState, MockSuperEvent> {
      LoadingWasRequested.self
      ReloadingWasRequested.self
    } transition: { _, _ in
      Transition(state: TestedState.loading)
      Output(sideEffect: { TestedEvent.loadingSucceededWithValue1701 })
    }

    // When
    receivedMealyTransition = await sut.mealyTransition(TestedState.idle, TestedEvent.loadingSucceededWithValue1701)

    // Then
    XCTAssertNil(
      receivedMealyTransition,
      """
      Expected mealy transition to be `nil` when wrong event type passed,
      but got \(String(describing: receivedMealyTransition)) instead.
      """
    )
  }
}

// MARK: tests when `guard` statement

extension OnTests {
  func test_init_whenGuardTrue_setsMealyTransition() async {
    // Given
    sut = On<Idle, MockSuperState, MockSuperEvent>(event: LoadingWasRequested.self) { state, event in
      XCTAssertEqual(anyLhs: state, anyRhs: Tested.expectedStateInGuard)
      XCTAssertEqual(anyLhs: event, anyRhs: Tested.expectedEventInGuard)
      return true
    } transition: { _, _ in
      Tested.assertableMealyTransition.transition
      Tested.assertableMealyTransition.output
    }

    // When
    receivedMealyTransition = await sut.mealyTransition(Tested.expectedStateInGuard, Tested.expectedEventInGuard)

    // Then
    let expected = OneOfEvents(LoadingWasRequested.self)
    let received = sut.oneOfEvents
    XCTAssertEqual(
      expected,
      received,
      "Expected events to be \(expected) but got \(received) instead."
    )

    await XCTAssert(received: receivedMealyTransition, isFrom: Tested.assertableMealyTransition)
  }

  func test_mealyTransition_whenGuardTrueAndWrongEventType_returnsNil() async {
    // Given
    sut = On<Idle, MockSuperState, MockSuperEvent>(event: LoadingWasRequested.self) { _, _ in
      true
    } transition: { _, _ in
      Transition(state: TestedState.loading)
      Output(sideEffect: { TestedEvent.loadingSucceededWithValue1701 })
    }

    // When
    receivedMealyTransition = await sut.mealyTransition(TestedState.idle, TestedEvent.loadingSucceededWithValue1701)

    // Then
    XCTAssertNil(
      receivedMealyTransition,
      """
      Expected mealy transition to be `nil` when wrong event type passed,
      but got \(String(describing: receivedMealyTransition)) instead.
      """
    )
  }

  func test_init_withOneOfEventsAndGuard_setsMealyTransition() async {
    // Given
    sut = On<Idle, MockSuperState, MockSuperEvent> {
      LoadingWasRequested.self
      ReloadingWasRequested.self
    } guard: { state, event in
      XCTAssertEqual(anyLhs: state, anyRhs: TestedState.idle)
      XCTAssertEqual(anyLhs: event, anyRhs: TestedEvent.loadingRequestedWithValue1701)
      return true
    } transition: { _, _ in
      Tested.assertableMealyTransition.transition
      Tested.assertableMealyTransition.output
    }

    // When
    receivedMealyTransition = await sut.mealyTransition(Tested.expectedStateInGuard, Tested.expectedEventInGuard)

    // Then
    let expected = OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
    let received = sut.oneOfEvents
    XCTAssertEqual(
      expected,
      received,
      "Expected events to be \(expected) but got \(received) instead."
    )

    await XCTAssert(received: receivedMealyTransition, isFrom: Tested.assertableMealyTransition)
  }

  func test_init_withEventsAndGuard_setsMealyTransition() async {
    // Given
    sut = On<Idle, MockSuperState, MockSuperEvent>(
      events:
      LoadingWasRequested.self,
      ReloadingWasRequested.self
    ) { state, event in
      XCTAssertEqual(anyLhs: state, anyRhs: TestedState.idle)
      XCTAssertEqual(anyLhs: event, anyRhs: TestedEvent.loadingRequestedWithValue1701)
      return true
    } transition: { _, _ in
      Tested.assertableMealyTransition.transition
      Tested.assertableMealyTransition.output
    }

    // When
    receivedMealyTransition = await sut.mealyTransition(TestedState.idle, TestedEvent.loadingRequestedWithValue1701)

    // Then
    let expected = OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
    let received = sut.oneOfEvents
    XCTAssertEqual(
      expected,
      received,
      "Expected events to be \(expected) but got \(received) instead."
    )

    await XCTAssert(received: receivedMealyTransition, isFrom: Tested.assertableMealyTransition)
  }

  func test_mealyTransition_whenSetWithOneOfEventsAndGuardInitializerAndWrondEventTypePassed_returnsNil() async {
    // Given
    sut = On<Idle, MockSuperState, MockSuperEvent> {
      LoadingWasRequested.self
      ReloadingWasRequested.self
    } guard: { _, _ in
      true
    } transition: { _, _ in
      Transition(state: TestedState.loading)
      Output(sideEffect: { TestedEvent.loadingSucceededWithValue1701 })
    }

    // When
    receivedMealyTransition = await sut.mealyTransition(TestedState.idle, TestedEvent.loadingSucceededWithValue1701)

    // Then
    XCTAssertNil(
      receivedMealyTransition,
      """
      Expected mealy transition to be `nil` when wrong event type passed,
      but got \(String(describing: receivedMealyTransition)) instead.
      """
    )
  }

  func test_mealyTransition_whenSetWithEventsAndGuardInitializerAndWrongEventTypePassed_returnsNil() async {
    // Given
    sut = On<Idle, MockSuperState, MockSuperEvent>(
      events:
      LoadingWasRequested.self,
      ReloadingWasRequested.self
    ) { _, _ in
      true
    } transition: { _, _ in
      Transition(state: TestedState.loading)
      Output(sideEffect: { TestedEvent.loadingSucceededWithValue1701 })
    }

    // When
    receivedMealyTransition = await sut.mealyTransition(TestedState.idle, TestedEvent.loadingSucceededWithValue1701)

    // Then
    XCTAssertNil(
      receivedMealyTransition,
      """
      Expected mealy transition to be `nil` when wrong event type passed,
      but got \(String(describing: receivedMealyTransition)) instead.
      """
    )
  }
}
