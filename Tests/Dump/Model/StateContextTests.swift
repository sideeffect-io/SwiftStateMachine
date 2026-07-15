import StateMachineCore
import XCTest
@testable import StateMachineDump

final class StateContextTests: XCTestCase {
  func test_equal_whenHaveSameStateMachinesIdsAndSameState_returnsTrue() {
    let uuid = UUID()
    let state = Loading()

    // Given
    let lhs = StateContext(stateMachineId: uuid, state: state)
    let rhs = StateContext(stateMachineId: uuid, state: state)

    // When
    let isEqual = lhs == rhs

    // Then
    XCTAssertTrue(
      isEqual,
      "Expected StateContexts to be equal when having same ids and states, but received they are not equal instead"
    )
  }

  func test_equal_whenHaveDifferentStateMachineIds_returnsFalse() {
    let state = Loading()

    // Given
    let lhs = StateContext(stateMachineId: UUID(), state: state)
    let rhs = StateContext(stateMachineId: UUID(), state: state)

    // When
    let isEqual = lhs == rhs

    // Then
    XCTAssertFalse(
      isEqual,
      "Expected StateContexts to not be equal when having different ids, but received they are equal instead"
    )
  }

  func test_equal_whenHaveDifferentStates_returnsFalse() {
    let uuid = UUID()

    // Given
    let lhs = StateContext(stateMachineId: uuid, state: Loaded(value: 1))
    let rhs = StateContext(stateMachineId: uuid, state: Loaded(value: 2))

    // When
    let isEqual = lhs == rhs

    // Then
    XCTAssertFalse(
      isEqual,
      "Expected StateContexts to not be equal when having different states, but received they are equal instead"
    )
  }

  func test_equal_whenHaveNonEquatableStates_returnsFalse() {
    struct NonEquatableState: State {
      var superState: NonEquatableState {
        self
      }
    }

    let uuid = UUID()

    // Given
    let lhs = StateContext(stateMachineId: uuid, state: NonEquatableState())
    let rhs = StateContext(stateMachineId: uuid, state: NonEquatableState())

    // When
    let isEqual = lhs == rhs

    // Then
    XCTAssertFalse(
      isEqual,
      "Expected StateContexts to not be equal when having non Equatable states, but received they are equal instead"
    )
  }

  func test_equal_whenComparedWithItselfAndStateIsNotEquatable_returnsTrue() {
    struct NonEquatableState: State {
      var superState: NonEquatableState { self }
    }

    let context = StateContext(stateMachineId: UUID(), state: NonEquatableState())

    XCTAssertEqual(context, context)
  }
}
