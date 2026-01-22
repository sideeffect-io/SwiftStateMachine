import StateMachineCore

public let defaultDumpStateMachine = AsyncStateMachine<DumpState, DumpEvent>(initial: DumpState(stateContexts: [:])) {
  When(state: DumpState.self) {
    On(event: DidObserveTransition.self) { state, event in
      Transition {
        var stateContexts = state.stateContexts
        stateContexts[event.stateMachineId] = StateContext(
          stateMachineId: event.stateMachineId,
          state: event.state
        )
        return DumpState(stateContexts: stateContexts)
      }
    }

    On(event: DidObserveDeinit.self) { state, event in
      Transition {
        var stateContexts = state.stateContexts
        stateContexts[event.stateMachineId] = nil
        return DumpState(stateContexts: stateContexts)
      }
    }

    On(event: DidRequestDump.self) { state, event in
      Output {
        await event.dumpStateContexts(state.toStateContextArray())
        return nil
      }
    }
  }
}.disableLog()
