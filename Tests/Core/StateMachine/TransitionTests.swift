import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class TransitionTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: Transition<MockSuperState>!

  // MARK: - Methods

  func test_init_withState_setsState() async {
    // Given
    let expectedState = TestedState.idle

    // When
    sut = Transition(state: expectedState)

    // Then
    let receivedState = await sut.state()

    let receivedStateTyped = receivedState as? Idle
    XCTAssertEqual(
      receivedStateTyped,
      expectedState,
      "Expected state \(expectedState), but got \(String(describing: receivedStateTyped)) instead."
    )
  }

  func test_init_withFactory_setsState() async {
    // Given
    let expectedState = TestedState.idle

    // When
    sut = Transition {
      expectedState
    }

    // Then
    let receivedState = await sut.state()
    let receivedStateTyped = receivedState as? Idle
    XCTAssertEqual(
      receivedStateTyped,
      expectedState,
      "Expected state \(expectedState), but got \(String(describing: receivedStateTyped)) instead."
    )
  }
}
