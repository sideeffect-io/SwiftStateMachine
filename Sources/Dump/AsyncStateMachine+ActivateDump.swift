import StateMachineCore

extension AsyncStateMachine {
  @discardableResult
  /// It allows to dump every new state into an internal state machine which collects them.
  /// It also optionally tracks the state machine's deinit so the dump is cleared when it is released from the memory.
  /// It is then possible to dump a snapshot of every tracked state machines.
  /// - Parameters:
  ///  - trackDeinit: `true` if the deinit of the state machine should be tracked (`true` by default).
  ///  - dumpMediator: The mediator used to dump all the state machine transitions.
  ///  By default we will use an internal global ``Mediator``.
  /// - Returns: The state machine itself
  public func activateDump(
    trackDeinit: Bool = true,
    dumpMediator: Mediator<DumpEvent> = defaultDumpMediator
  ) -> Self {
    // dump initial state
    onInitialState { stateMachineId, initialState in
      dumpMediator.sendToReceivers(event: DidObserveTransition(stateMachineId: stateMachineId, state: initialState))
    }

    // dump transitions
    connectAsSender(to: dumpMediator) { stateMachineId, _, _, newState in
      DidObserveTransition(stateMachineId: stateMachineId, state: newState)
    }

    // dump deinit
    if trackDeinit {
      onDeinit { stateMachineId in
        dumpMediator.sendToReceivers(event: DidObserveDeinit(stateMachineId: stateMachineId))
      }
    }

    return self
  }
}
