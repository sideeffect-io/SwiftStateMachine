import StateMachineCore

public func makeStateMachine() -> AsyncStateMachine<ElevatorState, ElevatorEvent> {
  makeStateMachine(initial: ElevatorIsOpen(persons: 0))
}

func makeStateMachine(initial: some State<ElevatorState>) -> AsyncStateMachine<ElevatorState, ElevatorEvent> {
  AsyncStateMachine(initial: initial) {
    When(state: ElevatorIsOpen.self) {
      On(event: DidEntered.self) { state, _ in
        state.persons + 1 <= 5
      } transition: { state, _ in
        Transition(state: ElevatorIsOpen(persons: state.persons + 1))
      }

      On(event: DidEntered.self) { state, _ in
        state.persons + 1 > 5
      } transition: { state, _ in
        Transition(state: ElevatorIsInWarning(persons: state.persons + 1))
      }

      On(event: DidLeft.self) { state, _ in
        state.persons - 1 >= 0
      } transition: { state, _ in
        Transition(state: ElevatorIsOpen(persons: state.persons - 1))
      }

      On(event: DidRequestToClose.self) { state, _ in
        Transition(state: ElevatorIsClosed(persons: state.persons))
      }
    }

    When(state: ElevatorIsClosed.self) {
      On(event: DidRequestToOpen.self) { state, _ in
        Transition(state: ElevatorIsOpen(persons: state.persons))
      }
    }

    When(state: ElevatorIsInWarning.self) {
      On(event: DidEntered.self) { state, _ in
        Transition(state: ElevatorIsInWarning(persons: state.persons + 1))
      }

      On(event: DidLeft.self) { state, _ in
        state.persons - 1 > 5
      } transition: { state, _ in
        Transition(state: ElevatorIsInWarning(persons: state.persons - 1))
      }

      On(event: DidLeft.self) { state, _ in
        state.persons - 1 <= 5
      } transition: { state, _ in
        Transition(state: ElevatorIsOpen(persons: state.persons - 1))
      }
    }
  }
}
