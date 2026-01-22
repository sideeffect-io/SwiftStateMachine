import StateMachineCore

// MARK: Public

public func makeCancellingStateMachine(load: LoadOutput) -> AsyncStateMachine<ClicsState, ClicsEvent> {
  makeCancellingStateMachine(initial: DataIsIdle(), load: load)
}

// MARK: Internal

func makeCancellingStateMachine(
  initial: some State<ClicsState>,
  load: LoadOutput
) -> AsyncStateMachine<ClicsState, ClicsEvent> {
  AsyncStateMachine(initial: initial) {
    When(
      states:
      DataIsIdle.self,
      DataIsLoading.self
    ) {
      On(event: DidRequestLoading.self) { _, _ in
        Transition(state: DataIsLoading())
        Output(sideEffect: load(), lifecycle: Cancel(on: DidRequestLoading.self))
      }
    }

    When(state: DataIsLoading.self) {
      On(event: DidCompleteLoading.self) { _, _ in
        Transition(state: DataIsLoaded(numberOfLoads: 1))
      }
    }

    When(state: DataIsLoaded.self) {
      On(event: DidCompleteLoading.self) { state, _ in
        Transition(state: DataIsLoaded(numberOfLoads: state.numberOfLoads + 1))
      }
      On(event: DidRequestLoading.self) { _, _ in
        Output(sideEffect: load(), lifecycle: Cancel(on: DidRequestLoading.self))
      }
      On(event: DidRequestReset.self) { _, _ in
        Transition(state: DataIsIdle())
      }
    }
  }
}
