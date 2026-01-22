import StateMachineShared

/// https://en.wikipedia.org/wiki/Finite-state_machine
/// https://en.wikipedia.org/wiki/Mealy_machine
/// A ``StateMachine`` aims to regulate the values of the state according to certain rules.
/// A Mealy ``StateMachine`` is defined by:
/// - an initial ``State``
/// - a finite set of possible ``State``
/// - a finite set of possible ``Event`` (the input alphabet)
/// - a finite set of possible ``Output`` (the output alphabet)
/// - a transition function that drives the passage from one state to another (State + Event) -> State
/// - an output function that drives the emittion of outputs according to a state and an event (State + Event) -> Output
/// Being also an `Extended` state machine, states and events can have variables and transitions can be gated by `guard` statements.
/// https://en.wikipedia.org/wiki/Extended_finite-state_machine
public struct StateMachine<SuperState, SuperEvent>: Sendable {
  // MARK: - Lifecycle

  // MARK: Public

  /// Creates a Mealy ``StateMachine`` with an initial state.
  /// - Parameter initial: the initial state of the ``StateMachine``
  public init(initial: some State<SuperState>) {
    self.initial = initial
  }

  // MARK: - Typealiases

  // MARK: Public

  public typealias AnyState = any State<SuperState>
  public typealias AnyEvent = any Event<SuperEvent>
  public typealias GuardFunction = @Sendable (AnyState, AnyEvent) async -> Bool
  public typealias MealyTransitionFunction = @Sendable (AnyState, AnyEvent) async
    -> MealyTransition<SuperState, SuperEvent>?

  // MARK: - Properties

  // MARK: Internal

  let initial: AnyState
  var mealyTable: [TypesIdentifier: [MealyTransitionFunction]] = [:]

  // MARK: - Methods

  // MARK: Public

  /// Registers a Mealy transition function given a ``State`` and an ``Event``.
  /// The execution of this transition can be gated by the boolean value returned by the `guard` statement.
  /// Several Mealy transitions can be registered for the same pair state/event and be filtered out thanks to
  /// their `guard` statement. It is up to the developer to guarantee their mutual exclusion.
  /// - Parameters:
  ///   - state: the type of ``State`` for which the transition is active
  ///   - event: the type of ``Event`` for which the transition is active
  ///   - guard: the optional `guard` statement that can prevent the transition from being executed
  ///   - mealyTransition: the state transition function and the output function to create a potential new ``State``
  ///   with a potential ``Output`` to execute
  /// - Returns: The state machine augmented with the Mealy transition
  public func when<S: State<SuperState>, E: Event<SuperEvent>>(
    state: S.Type,
    on event: E.Type,
    guard: (@Sendable (S, E) async -> Bool)? = nil,
    mealyTransition: @Sendable @escaping (S, E) async -> MealyTransition<SuperState, SuperEvent>
  ) -> Self {
    let guardStatement: GuardFunction?
    if let `guard` {
      guardStatement = { anyState, anyEvent in
        guard let state = anyState as? S else { return false }
        guard let event = anyEvent as? E else { return false }

        return await `guard`(state, event)
      }
    } else {
      guardStatement = nil
    }

    let mealyTransition: MealyTransitionFunction = { anyState, anyEvent in
      guard let state = anyState as? S else { return nil }
      guard let event = anyEvent as? E else { return nil }

      return await mealyTransition(state, event)
    }

    return when(
      OneOfStates<SuperState>(state),
      on: OneOfEvents<SuperEvent>(event),
      guard: guardStatement,
      mealyTransition: mealyTransition
    )
  }

  /// Registers a Mealy transition function given combinations of ``State``s and an ``Event``.
  /// The execution of this transition can be gated by the boolean value returned by the `guard` statement.
  /// Several Mealy transitions can be registered for the same pair state/event and be filtered out thanks to
  /// their `guard` statement. It is up to the developer to guarantee their mutual exclusion.
  /// - Parameters:
  ///   - oneOfStates: the types of ``State`` for which the transition is active
  ///   - event: the type of ``Event`` for which the transition is active
  ///   - guard: the optional `guard` statement that can prevent the transition from being executed
  ///   - mealyTransition: the state transition function and the output function to create a potential new ``State``
  ///   with a potential ``Output`` to execute
  /// - Returns: The state machine augmented with the Mealy transition
  public func when<E: Event<SuperEvent>>(
    _ oneOfStates: OneOfStates<SuperState>,
    on event: E.Type,
    guard: (@Sendable (AnyState, E) async -> Bool)? = nil,
    mealyTransition: @Sendable @escaping (AnyState, E) async -> MealyTransition<SuperState, SuperEvent>
  ) -> Self {
    let guardStatement: GuardFunction?
    if let `guard` {
      guardStatement = { anyState, anyEvent in
        guard let event = anyEvent as? E else { return false }

        return await `guard`(anyState, event)
      }
    } else {
      guardStatement = nil
    }

    let mealyTransition: MealyTransitionFunction = { anyState, anyEvent in
      guard let event = anyEvent as? E else { return nil }

      return await mealyTransition(anyState, event)
    }

    return when(
      oneOfStates,
      on: OneOfEvents<SuperEvent>(event),
      guard: guardStatement,
      mealyTransition: mealyTransition
    )
  }

  /// Registers a Mealy transition function given conbinations of a ``State`` and ``Event``s.
  /// The execution of this transition can be gated by the boolean value returned by the `guard` statement.
  /// Several Mealy transitions can be registered for the same pair state/event and be filtered out thanks to
  /// their `guard` statement. It is up to the developer to guarantee their mutual exclusion.
  /// - Parameters:
  ///   - state: the type of ``State`` for which the transition is active
  ///   - oneOfEvents: the type of ``Event``s for which the transition is active
  ///   - guard: the optional `guard` statement that can prevent the transition from being executed
  ///   - mealyTransition: the state transition function and the output function to create a potential new ``State``
  ///   with a potential ``Output`` to execute
  /// - Returns: The state machine augmented with the Mealy transition
  public func when<S: State<SuperState>>(
    state: S.Type,
    on oneOfEvents: OneOfEvents<SuperEvent>,
    guard: (@Sendable (S, AnyEvent) async -> Bool)? = nil,
    mealyTransition: @Sendable @escaping (S, AnyEvent) async -> MealyTransition<SuperState, SuperEvent>
  ) -> Self {
    let guardStatement: GuardFunction?
    if let `guard` {
      guardStatement = { anyState, anyEvent in
        guard let state = anyState as? S else { return false }

        return await `guard`(state, anyEvent)
      }
    } else {
      guardStatement = nil
    }

    let mealyTransition: MealyTransitionFunction = { anyState, anyEvent in
      guard let state = anyState as? S else { return nil }
      guard oneOfEvents.contains(event: anyEvent) else { return nil }

      return await mealyTransition(state, anyEvent)
    }

    return when(
      OneOfStates<SuperState>(state),
      on: oneOfEvents,
      guard: guardStatement,
      mealyTransition: mealyTransition
    )
  }

  /// Registers a Mealy transition function given combinations of ``State``s/``Event``s types.
  /// The execution of this transition can be gated by the boolean value returned by the `guard` statement.
  /// Several Mealy transitions can be registered for the same pair state/event and be filtered out thanks to
  /// their `guard` statement. It is up to the developer to guarantee their mutual exclusion.
  /// - Parameters:
  ///   - oneOfStates: the types of ``State``s for which the transition is active
  ///   - oneOfEvents: the type of ``Event``s for which the transition is active
  ///   - guard: the optional `guard` statement that can prevent the transition from being executed
  ///   - mealyTransition: the state transition function and the output function to create a potential new ``State``
  ///   with a potential ``Output`` to execute
  /// - Returns: The state machine augmented with the Mealy transition
  public func when(
    _ oneOfStates: OneOfStates<SuperState>,
    on oneOfEvents: OneOfEvents<SuperEvent>,
    guard: GuardFunction? = nil,
    mealyTransition: @escaping MealyTransitionFunction
  ) -> Self {
    var mutableSelf = self

    // for every combination of state/event types we register the mealy transition in the table
    oneOfStates.states.forEach { state in
      oneOfEvents.events.forEach { event in
        let identifier = TypesIdentifier(lhsIdentifier: state, rhsIdentifier: event)

        let existingTransitions = mutableSelf.mealyTable[identifier] ?? []
        let newTransition: MealyTransitionFunction = { anyState, anyEvent in
          guard oneOfStates.contains(state: anyState) else { return nil }
          guard oneOfEvents.contains(event: anyEvent) else { return nil }

          if let `guard` {
            guard await `guard`(anyState, anyEvent) else { return nil }
          }

          return await mealyTransition(anyState, anyEvent)
        }

        mutableSelf.mealyTable[identifier] = existingTransitions + [newTransition]
      }
    }

    return mutableSelf
  }

  /// Returns the ``MealyTransition`` standing for an optional ``Transition`` and an optional ``Output`` given a ``State`` and an ``Event``.
  /// If there are several results registered for a pair state/event, the first ``MealyTransition`` returning a non nil ``Transition``
  /// or a non nil ``Output`` will be returned.
  /// - Parameters:
  ///   - state: the current ``State``
  ///   - event: the ``Event`` involved in the transition
  /// - Returns: the potential ``MealyTransition``
  public func transition(
    state: some State<SuperState>,
    event: some Event<SuperEvent>
  ) async -> MealyTransition<SuperState, SuperEvent>? {
    let identifier = TypesIdentifier(lhsValue: state, rhsValue: event)
    guard let mealyTransitions = mealyTable[identifier] else { return nil }
    for transition in mealyTransitions {
      if let result = await transition(state, event), result.isPerformable {
        return result
      }
    }
    return nil
  }
}
