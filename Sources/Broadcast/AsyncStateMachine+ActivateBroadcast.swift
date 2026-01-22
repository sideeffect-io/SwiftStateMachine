import Foundation
import os
import StateMachineCore

private let stateContextBroadcasterStorage = OSAllocatedUnfairLock<[UUID: StateContextBroadcaster]>(
  initialState: [UUID: StateContextBroadcaster]()
)

private var stateContextBroadcasters: [UUID: StateContextBroadcaster] {
  get {
    stateContextBroadcasterStorage.withLock { $0 }
  }
  set {
    stateContextBroadcasterStorage.withLock { $0 = newValue }
  }
}

/// It allows to broadcaststhe states of all state machines that called activateBroadcast()
/// - Warning: You need to call `StateContextBroadcaster.stop()` once you are done iterating on the stream or else the StateContextBroadcaster won't be deallocated.
/// - Returns: A `StateContextBroadcaster` with containing a stream of `StateContext`
public func makeStateContextBroadcaster() -> StateContextBroadcaster {
  let streamId = UUID()
  var monitor = StateContextMonitor()
  let (stream, continuation) = AsyncStream.makeStream(of: StateContext.self)
  monitor.broadcastStateContext = { stateContext in
    continuation.yield(stateContext)
  }
  continuation.onTermination = { @Sendable _ in
    stateContextBroadcasters[streamId] = nil
  }
  let broadcaster = StateContextBroadcaster(
    stream: stream,
    id: streamId,
    monitor: monitor,
    continuation: continuation
  )
  stateContextBroadcasters[streamId] = broadcaster
  return broadcaster
}

extension AsyncStateMachine {
  @discardableResult
  /// It allows to broadcast every new state using the broadcastedStateContexts AsyncStream.
  /// It is then possible to dump a snapshot of every tracked state machines.
  /// - Returns: The state machine itself
  public func activateBroadcast() -> Self {
    onLifecycleEvent { lifecycleEvent in
      let context: StateContext
      switch lifecycleEvent {
      case .initialState(let id, let state):
        context = StateContext(stateMachineId: id, currentState: state, event: nil, newState: nil)
      case .transition(let id, let state, let event, let newState):
        context = StateContext(stateMachineId: id, currentState: state, event: event, newState: newState)
      }
      stateContextBroadcasters.values.forEach {
        $0.monitor.broadcastStateContext(context)
      }
    }
    return self
  }
}
