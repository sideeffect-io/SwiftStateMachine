/// ``When`` is a building block of the DSL that allows to describe all the Mealy transitions that are possible for a set of ``State``s.
/// This block can be used in the context of ``StateMachine``.
public struct When<SuperState, SuperEvent> {

  // MARK: - Lifecycle

  // MARK: Public

  /// Creates a ``When`` block given a ``State`` and a list of ``On`` blocks that stand for every available Mealy transitions.
  ///
  /// ```
  /// When(state: Loading.self) {
  ///   On(event: LoadingHasSucceeded.self) { state, event in
  ///     Transition(state: Loaded(data: event.data))
  ///   }
  ///
  ///   On(event: LoadingHasFailed.self) { state, event in
  ///     event.error is LoadingError
  ///   } transition: {
  ///     Transition(state: Failed(error: event.error)
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - state: The ``State`` type for which the transitions are available
  ///   - builder: The blocks describing the Mealy transitions
  public init<S: State<SuperState>>(
    state: S.Type,
    @WhenBuilder<S, SuperState, SuperEvent> builder: () -> [On<S, SuperState, SuperEvent>]
  ) {
    oneOfStates = OneOfStates(state)
    let ons = builder()
    mealyTransitions = ons.map { on in
      let oneOfEvents = on.oneOfEvents
      let mealyTransition: @Sendable (AnyState, AnyEvent) async
        -> MealyTransition<SuperState, SuperEvent>? = { anyState, anyEvent in
          guard let state = anyState as? S else { return nil }
          return await on.mealyTransition(state, anyEvent)
        }
      return (oneOfEvents, mealyTransition)
    }
  }

  /// Creates a ``When`` block given a set of possible ``States``s
  /// and a list of ``On`` blocks that stand for every available Mealy transitions.
  ///
  /// ```
  /// When {
  ///   Loading.self
  ///   Reloading.self
  /// } transitions: {
  ///   On(event: LoadingHasSucceeded.self) { state, event in
  ///     Transition(state: Loaded(data: event.data))
  ///   }
  ///
  ///   On(event: LoadingHasFailed.self) { state, event in
  /// ```
  ///
  /// - Parameters:
  ///   - oneOfStates: The set of ``States`` types that will trigger the Mealy transition
  ///   - transitions: The blocks describing the Mealy transitions
  public init(
    @OneOfStatesBuilder<SuperState> _ oneOfStates: () -> OneOfStates<SuperState>,
    @WhenBuilder<any State<SuperState>, SuperState, SuperEvent> transitions: ()
      -> [On<any State<SuperState>, SuperState, SuperEvent>]
  ) {
    let oneOfStates = oneOfStates()
    self.oneOfStates = oneOfStates
    let ons = transitions()
    mealyTransitions = ons.map { on in
      let oneOfEvents = on.oneOfEvents
      let mealyTransition: @Sendable (AnyState, AnyEvent) async
        -> MealyTransition<SuperState, SuperEvent>? = { anyState, anyEvent in
          guard oneOfStates.contains(state: anyState) else { return nil }
          return await on.mealyTransition(anyState, anyEvent)
        }
      return (oneOfEvents, mealyTransition)
    }
  }

  /// Creates a ``When`` block given a set of possible ``States``s
  /// and a list of ``On`` blocks that stand for every available Mealy transitions.
  ///
  /// ```
  /// When(states:
  ///   Loading.self,
  ///   Reloading.self
  /// ) {
  ///   On(event: LoadingHasSucceeded.self) { state, event in
  ///     Transition(state: Loaded(data: event.data))
  ///   }
  ///
  ///   On(event: LoadingHasFailed.self) { state, event in
  ///     event.error is LoadingError
  ///   } transition: {
  ///     Transition(state: Failed(error: event.error)
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - oneOfStates: The set of ``States`` types that will trigger the Mealy transition
  ///   - transitions: The blocks describing the Mealy transitions
  public init(
    states: any State<SuperState>.Type...,
    @WhenBuilder<any State<SuperState>, SuperState, SuperEvent> transitions: ()
      -> [On<any State<SuperState>, SuperState, SuperEvent>]
  ) {
    let oneOfStates = OneOfStates(states)
    self.oneOfStates = oneOfStates
    let ons = transitions()
    mealyTransitions = ons.map { on in
      let oneOfEvents = on.oneOfEvents
      let mealyTransition: @Sendable (AnyState, AnyEvent) async
        -> MealyTransition<SuperState, SuperEvent>? = { anyState, anyEvent in
          guard oneOfStates.contains(state: anyState) else { return nil }
          return await on.mealyTransition(anyState, anyEvent)
        }
      return (oneOfEvents, mealyTransition)
    }
  }

  // MARK: - Typealiases

  // MARK: Internal

  typealias AnyState = any State<SuperState>
  typealias AnyEvent = any Event<SuperEvent>
  typealias MealyTransitionFunction = @Sendable (AnyState, AnyEvent) async -> MealyTransition<SuperState, SuperEvent>?

  // MARK: - Properties

  // MARK: Internal

  let oneOfStates: OneOfStates<SuperState>
  let mealyTransitions: [(oneOfEvents: OneOfEvents<SuperEvent>, transitionFunction: MealyTransitionFunction)]
}
