import StateMachineCore

public func makeStateMachine() -> AsyncStateMachine<WalletState, WalletEvent> {
  AsyncStateMachine(initial: WalletState(credits: 0)) {
    When(state: WalletState.self) {
      On(event: DidRequestToAddCreditsEvent.self) { state, event in
        Transition(state: WalletState(credits: state.credits + event.credits))
      }

      On(event: DidRequestToRemoveCreditsEvent.self, guard: { $0.credits >= $1.credits }) { state, event in
        Transition(state: WalletState(credits: state.credits - event.credits))
      }
    }
  }
}
