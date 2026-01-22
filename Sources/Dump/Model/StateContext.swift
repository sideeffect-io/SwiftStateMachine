import Foundation
import StateMachineCore
import StateMachineShared

/// Represents the value on any ``State`` at a given time.
public struct StateContext: Sendable, Equatable {
  // MARK: - Properties

  /// The unique id of the state machine that produced the state
  public let stateMachineId: UUID

  /// The current value for the state
  public let state: any State

  /// The instant of creation for the state
  public let timeStamp = Date.now

  // MARK: - Methods

  // MARK: Public

  public static func == (lhs: Self, rhs: Self) -> Bool {
    guard
      let lhsEquatable = lhs.state as? any Equatable,
      let rhsEquatable = rhs.state as? any Equatable else
    {
      return false
    }

    guard lhsEquatable.isEqual(rhsEquatable) else {
      return false
    }

    return lhs.stateMachineId == rhs.stateMachineId
  }
}
