import StateMachineCore
import StateMachineTest
import XCTest
@testable import Elevator

// swiftlint:disable implicitly_unwrapped_optional

final class StateMachineTests: XCTestCase {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = makeStateMachine(initial: TestedState.openNoOneIn)
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Types

  private enum TestedState {
    static let openNoOneIn = ElevatorIsOpen(persons: 0)
    static let open1PersonIn = ElevatorIsOpen(persons: 1)
    static let open2PersonsIn = ElevatorIsOpen(persons: 2)
    static let open3PersonsIn = ElevatorIsOpen(persons: 3)
    static let open5PersonsIn = ElevatorIsOpen(persons: 5)

    static let inWarning6PersonsIn = ElevatorIsInWarning(persons: 6)
    static let inWarning7PersonsIn = ElevatorIsInWarning(persons: 7)

    static let closed2PersonsIn = ElevatorIsClosed(persons: 2)
    static let closed5PersonsIn = ElevatorIsClosed(persons: 5)
  }

  private enum TestedEvent {
    static let personHasEntered = DidEntered()
    static let personHasLeft = DidLeft()
    static let openButtonPressed = DidRequestToOpen()
    static let closeButtonPressed = DidRequestToClose()
  }

  // MARK: - Properties

  var sut: AsyncStateMachine<ElevatorState, ElevatorEvent>!

  // MARK: - Methods

  func test_send_whenNoWarning_transitionsToExpectedState() async {
    // Given a state machine with initial state ElevatorIsOpen with 0 persons

    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      // When / Then
      await assertions.assert(state: TestedState.openNoOneIn)

      // When
      assertions.send(event: TestedEvent.personHasEntered)
      // Then
      await assertions.assert(state: TestedState.open1PersonIn)

      // When
      assertions.send(event: TestedEvent.personHasEntered)
      // Then
      await assertions.assert(state: TestedState.open2PersonsIn)

      // When
      assertions.send(event: TestedEvent.personHasEntered)
      // Then
      await assertions.assert(state: TestedState.open3PersonsIn)

      // When
      assertions.send(event: TestedEvent.personHasLeft)
      // Then
      await assertions.assert(state: TestedState.open2PersonsIn)

      // When
      assertions.send(event: TestedEvent.closeButtonPressed)
      // Then
      await assertions.assert(state: TestedState.closed2PersonsIn)

      // When
      assertions.send(event: TestedEvent.openButtonPressed)
      // Then
      await assertions.assert(state: TestedState.open2PersonsIn)
    }
  }

  func test_send_whenNoOneInAndPersonHasLeft_executesNoTransition() async {
    // Given a state machine with initial state ElevatorIsOpen with 0 persons

    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      // When / Then
      await assertions.assert(state: TestedState.openNoOneIn)

      // When
      assertions.send(event: TestedEvent.personHasEntered)
      // Then
      await assertions.assert(state: TestedState.open1PersonIn)

      // When
      assertions.send(event: TestedEvent.personHasLeft)
      // Then
      await assertions.assert(state: TestedState.openNoOneIn)

      // When
      assertions.send(event: TestedEvent.personHasLeft)
      // Then
      await assertions.assertNoTransition()
    }
  }

  func test_send_whenWarning_transitionsToExpectedState() async {
    // Given a state machine with initial state ElevatorIsOpen with 0 persons

    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      await assertions.assert(state: TestedState.openNoOneIn)

      for person in 1...5 {
        assertions.send(event: TestedEvent.personHasEntered)
        await assertions.assert(state: ElevatorIsOpen(persons: person))
      }

      assertions.send(event: TestedEvent.personHasEntered)
      await assertions.assert(state: TestedState.inWarning6PersonsIn)

      assertions.send(event: TestedEvent.personHasEntered)
      await assertions.assert(state: TestedState.inWarning7PersonsIn)

      assertions.send(event: TestedEvent.closeButtonPressed)
      assertions.send(event: DidLeft())
      await assertions.assert(state: TestedState.inWarning6PersonsIn)

      assertions.send(event: TestedEvent.personHasLeft)
      await assertions.assert(state: TestedState.open5PersonsIn)

      assertions.send(event: TestedEvent.closeButtonPressed)
      await assertions.assert(state: TestedState.closed5PersonsIn)
    }
  }
}
