import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class MealyTransitionTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: MealyTransition<MockSuperState, MockSuperEvent>!

  // MARK: - Methods

  func test_init_withTransitionAndOutput_setsTransitionAndOutput() async {
    let assertableTransition = Transition.makeAssertable(state: Loading())
    let assertableOutput = Output<MockSuperState, MockSuperEvent>
      .makeAssertable(event: TestedEvent.loadingSucceededWithValue1701)

    // Given
    sut = MealyTransition(
      transition: assertableTransition.transition,
      output: assertableOutput.output
    )

    // When
    let receivedTransition = sut.transition
    let receivedOutput = sut.output

    // Them
    await XCTAssert(received: receivedTransition, isFrom: assertableTransition)
    await XCTAssert(received: receivedOutput, isFrom: assertableOutput)
  }

  func test_init_withTransition_setsIsPerformableToTrue() async {
    // Given
    sut = MealyTransition<MockSuperState, MockSuperEvent>(
      transition: Transition(state: TestedState.loading),
      output: nil
    )

    // When, Then
    XCTAssertTrue(sut.isPerformable, "Expected `isPerformable` to be true but got \(sut.isPerformable) instead.")
  }

  func test_init_withOutput_setsIsPerformableToTrue() async {
    // Given
    sut = MealyTransition<MockSuperState, MockSuperEvent>(
      transition: nil,
      output: Output(sideEffect: { TestedEvent.loadingSucceededWithValue1701 })
    )

    // When, Then
    XCTAssertTrue(sut.isPerformable, "Expected `isPerformable` to be true but got \(sut.isPerformable) instead.")
  }
}
