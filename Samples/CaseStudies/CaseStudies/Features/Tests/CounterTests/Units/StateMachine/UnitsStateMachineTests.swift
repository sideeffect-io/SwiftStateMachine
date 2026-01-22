import StateMachineCore
import StateMachineTest
import XCTest
@testable import Counter

// swiftlint:disable implicitly_unwrapped_optional

final class UnitStateMachineTests: XCTestCase {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = makeUnitsStateMachine(initial: TestedState.fixedZeroValue)
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Types

  private enum TestedState {
    static let fixedZeroValue = ValueIsFixed(value: 0)
    static let increasingValue1 = ValueIsIncreasing(value: 1)
    static let increasingValue2 = ValueIsIncreasing(value: 2)
    static let increasingValue3 = ValueIsIncreasing(value: 3)
    static let decreasingValue1 = ValueIsDecreasing(value: 1)
  }

  private enum TestedEvent {
    static let decrease = DidRequestDecrease()
    static let increase = DidRequestIncrease()
  }

  // MARK: - Properties

  var sut: AsyncStateMachine<UnitsState, UnitsEvent>!

  // MARK: - Methods

  func test_send_validEvent_transitionsToExpectedState() async {
    // Given an async state machine

    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      // When / Then
      await assertions.assert(state: TestedState.fixedZeroValue)

      // When
      assertions.send(event: TestedEvent.decrease)
      assertions.send(event: TestedEvent.increase)
      // Then
      await assertions.assert(state: TestedState.increasingValue1)

      // When
      assertions.send(event: TestedEvent.increase)
      // Then
      await assertions.assert(state: TestedState.increasingValue2)

      // When
      assertions.send(event: TestedEvent.decrease)
      // Then
      await assertions.assert(state: TestedState.decreasingValue1)
    }
  }
}
