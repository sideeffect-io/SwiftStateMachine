import Foundation
import StateMachineCore
import StateMachineShared

// MARK: - DumpEvent

public enum DumpEvent { }

// MARK: - DidObserveTransition

struct DidObserveTransition: Event, Equatable {
  typealias SuperEvent = DumpEvent

  let stateMachineId: UUID
  let state: any State

  static func == (lhs: Self, rhs: Self) -> Bool {
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

// MARK: - DidObserveDeinit

struct DidObserveDeinit: Event, Equatable {
  typealias SuperEvent = DumpEvent

  let stateMachineId: UUID
}

// MARK: - DidRequestDump

struct DidRequestDump: Event {
  typealias SuperEvent = DumpEvent

  let dumpStateContexts: @Sendable ([StateContext]) async -> Void
}
