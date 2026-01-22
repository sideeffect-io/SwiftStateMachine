import Foundation
import StateMachineShared

extension AsyncStateMachine {
  /// Represents different events in the lifecycle of a system.
  /// This enum is Sendable, making it suitable for concurrent processing.
  public enum LifecycleEvent: Sendable {

    /// Initial state event.
    /// - Parameters:
    ///   - id: The unique identifier of the state machine.
    ///   - state: The initial state of the state machine.
    case initialState(id: UUID, state: AnyState)

    /// Transition event.
    /// - Parameters:
    ///   - id: The unique identifier of the state machine
    ///   - state: The current state before the transition.
    ///   - event: The event triggering the transition.
    ///   - newState: The new state after the transition.
    case transition(id: UUID, state: AnyState, event: AnyEvent, newState: AnyState)

    public var currentState: AnyState {
      switch self {
      case .initialState(_, let state), .transition(_, let state, _, _): state
      }
    }

    public var receivedEvent: AnyEvent? {
      switch self {
      case .initialState: nil
      case .transition(_, _, let event, _): event
      }
    }

    public var newState: AnyState? {
      switch self {
      case .initialState: nil
      case .transition(_, _, _, let newState): newState
      }
    }
  }
}
