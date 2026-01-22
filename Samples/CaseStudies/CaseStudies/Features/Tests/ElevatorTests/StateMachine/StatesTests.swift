import StateMachineCore
import XCTest
@testable import Elevator

// swiftlint:disable implicitly_unwrapped_optional

final class StatesTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
    expected = nil
    received = nil
  }

  // MARK: - Types

  private enum TestedState {
    static let openWithPeopleInside = ElevatorState(
      numberOfPersons: "4",
      canAddPerson: true,
      canRemovePerson: true,
      canPressOpen: false,
      canPressClose: true,
      symbol: "lock.open.fill",
      message: "More people can enter, or you can close the elevator"
    )

    static let openEmpty = ElevatorState(
      numberOfPersons: "0",
      canAddPerson: true,
      canRemovePerson: false,
      canPressOpen: false,
      canPressClose: true,
      symbol: "lock.open.fill",
      message: "More people can enter, or you can close the elevator"
    )

    static let closedWithPeopleInside = ElevatorState(
      numberOfPersons: "1",
      canAddPerson: false,
      canRemovePerson: false,
      canPressOpen: true,
      canPressClose: false,
      symbol: "lock.fill",
      message: "You can open the elevator"
    )

    static let inWarning = ElevatorState(
      numberOfPersons: "6",
      canAddPerson: true,
      canRemovePerson: true,
      canPressOpen: false,
      canPressClose: false,
      symbol: "exclamationmark.triangle.fill",
      message: "Too many people, some should leave"
    )
  }

  // MARK: - Properties

  var sut: (any StateMachineCore.State)!
  var expected: ElevatorState!
  var received: ElevatorState!

  // MARK: - Methods

  func test_openState_withPeopleIn_derivesExpectedSuperState() {
    // Given
    sut = ElevatorIsOpen(persons: 4)

    // When
    received = sut.superState as? ElevatorState

    // Then
    expected = TestedState.openWithPeopleInside
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the superState derived from an Open state with people in to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }

  func test_openState_withNoOneIn_derivesExpectedSuperState() {
    // Given
    sut = ElevatorIsOpen(persons: 0)

    // When
    received = sut.superState as? ElevatorState

    // Then
    expected = TestedState.openEmpty
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the superState derived from an Open state with no one in to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }

  func test_closedState_withPeopleIn_derivesExpectedSuperSTate() {
    // Given
    sut = ElevatorIsClosed(persons: 1)

    // When
    received = sut.superState as? ElevatorState

    // Then
    expected = TestedState.closedWithPeopleInside
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the superState derived from a Closed state with people in to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }

  func test_inWarningState_derivesExpectedSuperState() {
    // Given
    sut = ElevatorIsInWarning(persons: 6)

    // When
    received = sut.superState as? ElevatorState

    // Then
    expected = TestedState.inWarning
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the superState derived from an ElevatorIsInWarning state to be \(String(describing: expected)),
      but got \(String(describing: received)) instead.
      """
    )
  }
}
