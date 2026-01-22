import StateMachineCore
import StateMachineTest
import XCTest
@testable import Wallet

// swiftlint:disable implicitly_unwrapped_optional

final class StateMachineTests: XCTestCase {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = makeStateMachine()
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Types

  private enum TestedState {
    static let noCreditState = WalletState(credits: 0)
    static let tenCreditsState = WalletState(credits: 10)
    static let heightCreditsState = WalletState(credits: 8)
  }

  private enum TestedEvent {
    static let didRequestToAdd10Credits = DidRequestToAddCreditsEvent(credits: 10)
    static let didRequestToRemove2Credits = DidRequestToRemoveCreditsEvent(credits: 2)
    static let didRequestToRemove20Credits = DidRequestToRemoveCreditsEvent(credits: 20)
  }

  // MARK: - Properties

  var sut: AsyncStateMachine<WalletState, WalletEvent>!

  // MARK: - Methods

  func test_send_transitionToExpectedState() async {
    // Given a state machine
    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      // When / Then
      await assertions.assert(state: TestedState.noCreditState)

      // When
      assertions.send(event: TestedEvent.didRequestToAdd10Credits)
      // Then
      await assertions.assert(state: TestedState.tenCreditsState)

      // When
      assertions.send(event: TestedEvent.didRequestToRemove2Credits)
      // Then
      await assertions.assert(state: TestedState.heightCreditsState)
    }
  }

  func test_send_whenNotEnoughCredits_doesNotTransition() async {
    // Given a state machine
    await XCTAssertNoTransition(
      asyncStateMachine: sut,
      when: TestedState.heightCreditsState,
      on: TestedEvent.didRequestToRemove20Credits
    )
  }
}
