import Foundation
import os
import StateMachineCore

private struct CollectSession: Sendable {
  let task: Task<Void, Never>
  let dumpStateMachineID: UUID
  let dumpMediator: Mediator<DumpEvent>
}

private let collectSessionStorage = OSAllocatedUnfairLock<CollectSession?>(initialState: nil)
private let collectLifecycleLock = OSAllocatedUnfairLock<Void>(initialState: ())
var collectTask: Task<Void, Never>? {
  collectSessionStorage.withLock { $0?.task }
}

/// Starts collecting all the tracked state machine's states.
/// - Parameters:
///   - dumpStateMachine: The state machine connected to the `dumpMediator` as a receiver and aggregating
///   all the transitions from the state machines where `activateDump(dumpMediator: dumpMediator)` has been called.
///   By default we will use an internal global ``AsyncStateMachine``.
///   - dumpMediator: The mediator to which the `dumpStateMachine` is connected as a receiver and used in the calls
///   to `activateDump(dumpMediator: dumpMediator)` on the tracked state machines.
///   By default we will use an internal global ``Mediator``.
public func startCollecting(
  dumpStateMachine: AsyncStateMachine<DumpState, DumpEvent> = defaultDumpStateMachine,
  dumpMediator: Mediator<DumpEvent> = defaultDumpMediator
) {
  collectLifecycleLock.withLock { _ in
    let previousSession = collectSessionStorage.withLock { session -> CollectSession? in
      defer { session = nil }
      return session
    }
    previousSession?.task.cancel()
    if let previousSession {
      previousSession.dumpMediator.unregisterReceiver(id: previousSession.dumpStateMachineID)
    }

    dumpStateMachine.connectAsReceiver(to: dumpMediator)
    let task = Task {
      for await _ in dumpStateMachine { }
    }
    collectSessionStorage.withLock { session in
      session = CollectSession(
        task: task,
        dumpStateMachineID: dumpStateMachine.id,
        dumpMediator: dumpMediator
      )
    }
  }
}

/// Stop collecting all the tracked state machine's states.
public func stopCollecting() {
  collectLifecycleLock.withLock { _ in
    let session = collectSessionStorage.withLock { session -> CollectSession? in
      defer { session = nil }
      return session
    }
    session?.task.cancel()
    if let session {
      session.dumpMediator.unregisterReceiver(id: session.dumpStateMachineID)
    }
  }
}
