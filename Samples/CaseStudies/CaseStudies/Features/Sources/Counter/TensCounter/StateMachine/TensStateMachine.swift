import StateMachineCore

public func makeTensStateMachine() -> AsyncStateMachine<TensState, TensEvent> {
  makeTensStateMachine(initial: TensState(value: 0))
}

func makeTensStateMachine(initial: some State<TensState>) -> AsyncStateMachine<TensState, TensEvent> {
  AsyncStateMachine(initial: initial) {
    When(state: TensState.self) {
      On(event: TensEvent.self) { _, event in
        Transition(state: TensState(value: event.value))
      }
    }
  }
}
