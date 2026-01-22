import XCTest
@testable import StateMachineCore

// MARK: - WhenTests

// swiftlint:disable implicitly_unwrapped_optional

final class WhenTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
    mealyTransition = nil
  }

  // MARK: - Types

  private enum TestedAssertableMealyTransition {
    static let loadingWithSuccess = MealyTransition.makeAssertable(
      transitionTo: TestedState.loading,
      emit: TestedEvent.loadingSucceededWithValue1
    )
  }

  // MARK: - Properties

  var sut: When<MockSuperState, MockSuperEvent>!
  var mealyTransition: (
    (any State<MockSuperState>, any Event<MockSuperEvent>) async
      -> MealyTransition<MockSuperState, MockSuperEvent>?
  )!
}

// MARK: tests when state
extension WhenTests {
  func test_init_setsMealyTransitions() async {
    // Given
    sut = When<MockSuperState, MockSuperEvent>(state: Idle.self) {
      On(event: LoadingHasSucceeded.self) { _, _ in
        TestedAssertableMealyTransition.loadingWithSuccess.transition
        TestedAssertableMealyTransition.loadingWithSuccess.output
      }
    }

    // When
    mealyTransition = sut.mealyTransitions.first?.transitionFunction

    // Then
    let receivedStates = sut.oneOfStates
    let expectedStates = OneOfStates(Idle.self)
    XCTAssertEqual(
      receivedStates,
      expectedStates,
      "Expected \(expectedStates), but got \(receivedStates) instead."
    )
    let receivedMealyTransition = await mealyTransition?(TestedState.idle, TestedEvent.loadingSucceededWithValue1)
    await XCTAssert(received: receivedMealyTransition, isFrom: TestedAssertableMealyTransition.loadingWithSuccess)
  }

  func test_mealyTransitions_whenWrongStateType_returnNil() async {
    // Given
    sut = When<MockSuperState, MockSuperEvent>(state: Loading.self) {
      On(event: LoadingHasSucceeded.self) { _, event in
        Transition(state: Loaded(value: event.value))
      }
    }

    // When
    mealyTransition = sut.mealyTransitions[0].transitionFunction

    // Then
    let receivedMealyTransition = await mealyTransition(TestedState.idle, TestedEvent.loadingSucceededWithValue1)
    XCTAssertNil(
      receivedMealyTransition,
      """
      Expected the mealy transition to be `nil`, but got \(String(describing: receivedMealyTransition)) instead
      """
    )
  }
}

// MARK: tests when OneOfStates

extension WhenTests {
  func test_init_withOneOfStates_setsMealyTransitions() async {
    // Given
    sut = When<MockSuperState, MockSuperEvent> {
      Idle.self
      Loading.self
    } transitions: {
      On(event: LoadingHasSucceeded.self) { _, _ in
        TestedAssertableMealyTransition.loadingWithSuccess.transition
        TestedAssertableMealyTransition.loadingWithSuccess.output
      }
    }

    // When
    mealyTransition = sut.mealyTransitions.first?.transitionFunction

    // Then
    let receivedStates = sut.oneOfStates
    let expectedStates = OneOfStates(Idle.self, Loading.self)
    XCTAssertEqual(
      receivedStates,
      expectedStates,
      "Expected \(expectedStates), but got \(receivedStates) instead."
    )
    let receivedMealyTransition = await mealyTransition?(TestedState.idle, TestedEvent.loadingSucceededWithValue1)
    await XCTAssert(received: receivedMealyTransition, isFrom: TestedAssertableMealyTransition.loadingWithSuccess)
  }

  func test_mealyTransitions_whenSetWithOneOfStatesInitializerAndWrongStateTypePassed_returnNil() async {
    // Given
    sut = When<MockSuperState, MockSuperEvent> {
      Idle.self
      Loading.self
    } transitions: {
      On(event: LoadingHasSucceeded.self) { _, event in
        Transition(state: Loaded(value: event.value))
      }
    }

    // When
    mealyTransition = sut.mealyTransitions[0].transitionFunction

    // Then
    let receivedMealyTransition = await mealyTransition(
      TestedState.loaded,
      TestedEvent.loadingSucceededWithValue1
    )
    XCTAssertNil(
      receivedMealyTransition,
      """
      Expected the mealy transition to be `nil`, but got \(String(describing: receivedMealyTransition)) instead
      """
    )
  }
}

// MARK: tests when states

extension WhenTests {
  func test_init_withStates_setsMealyTransitions() async {
    // Given
    sut = When<MockSuperState, MockSuperEvent>(
      states:
      Idle.self,
      Loading.self
    ) {
      On(event: LoadingHasSucceeded.self) { _, _ in
        TestedAssertableMealyTransition.loadingWithSuccess.transition
        TestedAssertableMealyTransition.loadingWithSuccess.output
      }
    }

    // When
    let mealyTransitions = sut.mealyTransitions
    let mealyTransition = mealyTransitions.first?.transitionFunction

    // Then
    let receivedStates = sut.oneOfStates
    let expectedStates = OneOfStates(Idle.self, Loading.self)
    XCTAssertEqual(
      receivedStates,
      expectedStates,
      "Expected \(expectedStates), but got \(receivedStates) instead."
    )
    let receivedMealyTransition = await mealyTransition?(TestedState.idle, TestedEvent.loadingSucceededWithValue1)
    await XCTAssert(received: receivedMealyTransition, isFrom: TestedAssertableMealyTransition.loadingWithSuccess)
  }

  func test_mealyTransitions_whenSetWithStatesInitializerAndWrongStateTypePassed_returnsNil() async {
    // Given
    sut = When<MockSuperState, MockSuperEvent>(
      states:
      Idle.self,
      Loading.self
    ) {
      On(event: LoadingHasSucceeded.self) { _, event in
        Transition(state: Loaded(value: event.value))
      }
    }

    // When
    mealyTransition = sut.mealyTransitions[0].transitionFunction

    // Then
    let receivedMealyTransition = await mealyTransition(
      TestedState.loaded,
      TestedEvent.loadingSucceededWithValue1
    )
    XCTAssertNil(
      receivedMealyTransition,
      """
      Expected the mealy transition to be `nil`, but got \(String(describing: receivedMealyTransition)) instead
      """
    )
  }
}
