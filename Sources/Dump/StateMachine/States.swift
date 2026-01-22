import Foundation
import OrderedCollections
import StateMachineCore

public struct DumpState: State, Sendable, Equatable {
  /// All the contexts for the tracked states
  public let stateContexts: OrderedDictionary<UUID, StateContext>

  public var superState: Self {
    self
  }

  func toStateContextArray() -> [StateContext] {
    Array(stateContexts.values)
  }
}
