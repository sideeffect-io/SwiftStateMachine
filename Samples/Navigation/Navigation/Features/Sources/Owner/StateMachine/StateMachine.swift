import StateMachineCore

public func makeStateMachine(load: Load) -> AsyncStateMachine<OwnerState, OwnerEvent> {
  AsyncStateMachine(initial: OwnerIsIdle()) {
    When(states: OwnerIsIdle.self, OwnerIsLoaded.self) {
      On(event: DidRequestLoading.self) { _, event in
        Transition(state: OwnerIsLoading())
        Output(sideEffect: load(id: event.id))
      }
    }

    When(state: OwnerIsLoading.self) {
      On(event: DidSucceedToLoad.self) { _, event in
        Transition(state: OwnerIsLoaded(owner: event.owner))
      }
    }
  }
}
