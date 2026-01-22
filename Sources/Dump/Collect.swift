import os
import StateMachineCore

let collectTaskStorage = OSAllocatedUnfairLock<Task<Void, Never>?>(initialState: nil)
var collectTask: Task<Void, Never>? {
  collectTaskStorage.withLock { $0 }
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
  dumpMediator: Mediator<DumpEvent> = dedaultDumpMediator
) {
  dumpStateMachine.connectAsReceiver(to: dumpMediator)
  let task = Task {
    for await _ in dumpStateMachine { }
  }

  collectTaskStorage.withLock {
    $0 = task
  }
}

/// Stop collecting all the tracked state machine's states.
public func stopCollecting() {
  collectTaskStorage.withLock {
    $0?.cancel()
  }
}
