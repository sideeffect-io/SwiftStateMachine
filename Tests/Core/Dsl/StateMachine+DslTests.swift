import XCTest
@testable import StateMachineCore

// swiftlint:disable function_body_length
// swiftlint:disable implicitly_unwrapped_optional

final class StateMachineDslTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Types

  private enum TestedAssertableMealyTransition {
    static let loadingWithSuccess = MealyTransition.makeAssertable(
      transitionTo: TestedState.loading,
      emit: TestedEvent.loadingSucceededWithValue1701
    )

    static let failedWithRequest = MealyTransition.makeAssertable(
      transitionTo: TestedState.failed,
      emit: TestedEvent.loadingRequestedWithValue1701
    )

    static let loadedWithSuccess = MealyTransition.makeAssertable(
      transitionTo: TestedState.loaded,
      emit: TestedEvent.loadingSucceededWithValue1701
    )

    static let failedWithSuccess = MealyTransition.makeAssertable(
      transitionTo: TestedState.failed,
      emit: TestedEvent.loadingSucceededWithValue1701
    )
  }

  // MARK: - Properties

  var sut: StateMachine<MockSuperState, MockSuperEvent>!

  // MARK: - Methods

  func test_init_setsPredicateAndMealyTransition() async {
    // Given
    let expectedInitialState = Idle()

    sut = StateMachine<MockSuperState, MockSuperEvent>(initial: expectedInitialState) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self, guard: { _, _ in true }) { _, _ in
          TestedAssertableMealyTransition.loadingWithSuccess.transition
          TestedAssertableMealyTransition.loadingWithSuccess.output
        }

        On(event: LoadingWasRequested.self) { _, _ in
          false
        } transition: { _, _ in
          TestedAssertableMealyTransition.failedWithRequest.transition
          TestedAssertableMealyTransition.failedWithRequest.output
        }
      }

      When(state: Loading.self) {
        On(event: LoadingHasSucceeded.self) { _, _ in
          TestedAssertableMealyTransition.loadedWithSuccess.transition
          TestedAssertableMealyTransition.loadedWithSuccess.output
        }

        On(event: LoadingHasFailed.self) { _, _ in
          TestedAssertableMealyTransition.failedWithSuccess.transition
          TestedAssertableMealyTransition.failedWithSuccess.output
        }
      }
    }

    // Then
    let initialState = sut.initial as? Idle
    XCTAssertEqual(
      initialState,
      expectedInitialState,
      """
      Expected the initial state to be \(expectedInitialState),
      but gotr \(String(describing: initialState)) instead.
      """
    )

    let receivedMealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 3
    XCTAssertEqual(
      receivedMealyTableCount,
      expectedMealyTableCount,
      """
      Expected the mealy table count to be \(expectedMealyTableCount),
      but got \(receivedMealyTableCount) instead.
      """
    )

    // When
    let when1Transitions = sut.mealyTable[
      TypesIdentifier(lhsType: Idle.self, rhsType: LoadingWasRequested.self)
    ]!
    // Then
    let when1Count = when1Transitions.count
    let expectedCount1 = 2
    XCTAssertEqual(
      when1Count,
      expectedCount1,
      """
      Expected when1Count to be \(when1Count), but got \(expectedCount1) instead.
      """
    )
    let receivedMealyTransition1 = await when1Transitions[0](
      TestedState.idle,
      TestedEvent.loadingRequestedWithValue1701
    )
    await XCTAssert(received: receivedMealyTransition1, isFrom: TestedAssertableMealyTransition.loadingWithSuccess)

    // When
    let when2Transitions1 = sut.mealyTable[
      TypesIdentifier(lhsType: Loading.self, rhsType: LoadingHasSucceeded.self)
    ]!
    // Then
    let when2Count1 = when2Transitions1.count
    let expectedCount2 = 1
    XCTAssertEqual(
      when2Count1,
      expectedCount2,
      """
      Expected when2Count1 to be \(when2Count1), but got \(expectedCount2) instead.
      """
    )
    let receivedMealyTransition3 = await when2Transitions1[0](
      TestedState.loading,
      TestedEvent.loadingSucceededWithValue1701
    )
    await XCTAssert(received: receivedMealyTransition3, isFrom: TestedAssertableMealyTransition.loadedWithSuccess)

    // When
    let when2Transitions2 = sut.mealyTable[
      TypesIdentifier(lhsType: Loading.self, rhsType: LoadingHasFailed.self)
    ]!
    // Then
    let when2Count2 = when2Transitions2.count
    XCTAssertEqual(
      when2Count2,
      expectedCount2,
      """
      Expected when2Count2 to be \(when2Count2), but got \(expectedCount2) instead.
      """
    )
    let receivedMealyTransition4 = await when2Transitions2[0](TestedState.loading, TestedEvent.loadingFailed)
    await XCTAssert(received: receivedMealyTransition4, isFrom: TestedAssertableMealyTransition.failedWithSuccess)
  }
}
