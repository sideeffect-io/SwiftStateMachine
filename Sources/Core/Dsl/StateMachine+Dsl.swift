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
    id = nil
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

      for composite in when.compositeDefinitions {
        for state in oneOfStates.states {
          let existingComposites = compositesByState[state] ?? []
          compositesByState[state] = existingComposites + [composite]
        }
      }
    }
  }

  /// Creates a ``StateMachine`` from ``When`` building blocks, with an identifier.
  ///
  /// - Parameters:
  ///   - id: the identifier used to reference this state machine in composite configurations
  ///   - initial: the initial state
  ///   - builder: The blocks describing the Mealy transitions
  public init<ID>(
    id: ID.Type,
    initial: some State<SuperState>,
    @StateMachineBuilder<SuperState, SuperEvent> builder: () -> [When<SuperState, SuperEvent>]
  ) {
    self.id = ObjectIdentifier(id)
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

      for composite in when.compositeDefinitions {
        for state in oneOfStates.states {
          let existingComposites = compositesByState[state] ?? []
          compositesByState[state] = existingComposites + [composite]
        }
      }
    }
  }
}
