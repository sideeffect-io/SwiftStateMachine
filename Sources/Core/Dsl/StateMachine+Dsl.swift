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
    self.init(initial: initial)
    self = registering(whens: builder())
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
    self.init(id: id, initial: initial)
    self = registering(whens: builder())
  }
}
