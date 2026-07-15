import Foundation
import os
import StateMachineCore

private let stateContextContinuations = OSAllocatedUnfairLock<
  [UUID: AsyncStream<StateContext>.Continuation]
>(initialState: [:])

/// Creates an independent state-context subscriber.
public func makeStateContextBroadcaster() -> StateContextBroadcaster {
  let id = UUID()
  let (stream, continuation) = AsyncStream.makeStream(of: StateContext.self)
  continuation.onTermination = { @Sendable _ in
    stateContextContinuations.withLock { $0[id] = nil }
  }
  stateContextContinuations.withLock { $0[id] = continuation }
  return StateContextBroadcaster(stream: stream, continuation: continuation)
}

extension AsyncStateMachine {
  @discardableResult
  /// Broadcasts each lifecycle context to a snapshot of active subscribers.
  /// Continuations are yielded outside the registry lock, so subscriber
  /// termination cannot race with a read-modify-write of the registry.
  public func activateBroadcast() -> Self {
    onLifecycleEvent { lifecycleEvent in
      let context: StateContext
      switch lifecycleEvent {
      case .initialState(let id, let state):
        context = StateContext(stateMachineId: id, currentState: state, event: nil, newState: nil)
      case .transition(let id, let state, let event, let newState):
        context = StateContext(stateMachineId: id, currentState: state, event: event, newState: newState)
      }
      let continuations = stateContextContinuations.withLock { Array($0.values) }
      continuations.forEach { $0.yield(context) }
    }
    return self
  }
}
