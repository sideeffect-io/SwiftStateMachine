import os
import StateMachineCore

struct StateContextMonitor: Sendable {

  typealias BroadcastAction = @Sendable (StateContext) -> Void

  private let broadcastStateContextStorage = OSAllocatedUnfairLock<BroadcastAction>(initialState: { _ in })

  var broadcastStateContext: BroadcastAction {
    get {
      broadcastStateContextStorage.withLock { $0 }
    }
    set {
      broadcastStateContextStorage.withLock { $0 = newValue }
    }
  }
}
