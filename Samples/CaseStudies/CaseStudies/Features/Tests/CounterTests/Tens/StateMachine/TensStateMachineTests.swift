import StateMachineCore
import StateMachineTest
import XCTest
@testable import Counter

// swiftlint:disable implicitly_unwrapped_optional

final class TensStateMachineTests: XCTestCase {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = makeTensStateMachine(initial: TestedState.value5)
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Types

  private enum TestedState {
    static let value5 = TensState(value: 5)
    static let value10 = TensState(value: 10)
  }

  private enum TestedEvent {
    static let value10 = TensEvent(value: 10)
  }

  // MARK: - Properties

  var sut: AsyncStateMachine<TensState, TensEvent>!

  // MARK: - Methods

  func test_send_validEvent_transitionsToExpectedState() async {
    // Given an async state machine

    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      // When / Then
      await assertions.assert(state: TestedState.value5)

      // When
      assertions.send(event: TestedEvent.value10)
      // Then
      await assertions.assert(state: TestedState.value10)
    }
  }
}
