import StateMachineShared

extension StateMachine {
  // MARK: - Lifecycle

  // MARK: Public

  /// Creates a ``StateMachine`` from ``When`` building blocks.
  ///
  /// ```
  /// StateMachine<FeatureState, FeatureEvent>(initial: Idle()) {
  ///   When(state: Idle.self) {
  ///     On(event: LoadingWasRequested.self) { state, event in
  ///       Transition(state: Loading())
  ///       Output(sideEffect: load())
  ///     }
  ///   }
  ///
  ///   When(state: Loading.self) {
  ///     On(event: LoadingHasSucceeded.self) { state, event in
  ///       Transition(state: Loaded(data: event.data)
  ///     }
  ///
  ///     On(event: LoadingHasFailed.self) { state, event in
  ///       Transition(state: Failed(error: event.error)
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - initial: the initial state
  ///   - builder: The blocks describing the Mealy transitions
  public init(
    initial: some State<SuperState>,
    @StateMachineBuilder<SuperState, SuperEvent> builder: () -> [When<SuperState, SuperEvent>]
  ) {
    self.initial = initial

    for when in builder() {
      let oneOfStates = when.oneOfStates

      for mealyTransition in when.mealyTransitions {
        let oneOfEvents = mealyTransition.oneOfEvents

        // for every combination of state/event types we register the mealy transition in the table
        for state in oneOfStates.states {
          for event in oneOfEvents.events {
            let identifier = TypesIdentifier(lhsIdentifier: state, rhsIdentifier: event)

            let existingTransitions = mealyTable[identifier] ?? []
            let newTransition = mealyTransition.transitionFunction

            mealyTable[identifier] = existingTransitions + [newTransition]
          }
        }
      }
    }
  }
}
