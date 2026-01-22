import Foundation
import StateMachineCore
import StateMachineShared

/// Represents the value on any ``State`` at a given time.
public struct StateContext: Sendable {
  // MARK: - Properties
  /// The unique id of the state machine that produced the state
  public let stateMachineId: UUID

  /// The current value for the state
  public let currentState: any State

  /// The event producing the new state
  public let event: (any Event)?

  /// The new state produced by the event
  public let newState: (any State)?

  /// The instant of creation for the state
  public let timeStamp = Date.now
}
