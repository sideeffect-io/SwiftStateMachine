import StateMachineCore

public func makeUnitsStateMachine() -> AsyncStateMachine<UnitsState, UnitsEvent> {
  makeUnitsStateMachine(initial: ValueIsFixed(value: 0))
}

func makeUnitsStateMachine(initial: some State<UnitsState>) -> AsyncStateMachine<UnitsState, UnitsEvent> {
  AsyncStateMachine(initial: initial) {
    When(
      states:
      ValueIsFixed.self,
      ValueIsIncreasing.self,
      ValueIsDecreasing.self
    ) {
      On(event: DidRequestIncrease.self) { state, _ in
        Transition(state: ValueIsIncreasing(value: state.superState.value + 1))
      }

      On(event: DidRequestDecrease.self) { state, _ in
        state.superState.value > 0
      } transition: { state, _ in
        Transition(state: ValueIsDecreasing(value: state.superState.value - 1))
      }
    }
  }
}
