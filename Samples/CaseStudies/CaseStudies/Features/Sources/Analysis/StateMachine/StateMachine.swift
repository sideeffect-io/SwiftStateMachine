import StateMachineCore

public func makeStateMachine(
  performAnalysisOutput: PerformAnalysisOutput
) -> AsyncStateMachine<AnalysisState, AnalysisEvent> {
  makeStateMachine(initial: AnalysisIsIdle(), performAnalysisOutput: performAnalysisOutput)
}

func makeStateMachine(
  initial: some State<AnalysisState>,
  performAnalysisOutput: PerformAnalysisOutput
) -> AsyncStateMachine<AnalysisState, AnalysisEvent> {
  AsyncStateMachine(initial: initial) {
    When(state: AnalysisIsIdle.self) {
      On(event: DidRequestAnalysis.self) { _, event in
        Transition(state: AnalysisIsInProgress(identifier: event.identifier))
        Output(sideEffect: performAnalysisOutput())
      }
    }

    When(state: AnalysisIsInProgress.self) {
      On(event: DidCompleteAnalysis.self) { state, _ in
        Transition(state: AnalysisIsDone(identifier: state.identifier))
      }
      On(event: DidRequestAnalysisReset.self) { _, _ in
        Transition(state: AnalysisIsIdle())
      }
    }

    When(state: AnalysisIsDone.self) {
      On(event: DidRequestAnalysisReset.self) { _, _ in
        Transition(state: AnalysisIsIdle())
      }
    }
  }
}
