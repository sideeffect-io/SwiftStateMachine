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
    id = nil
    self.initial = initial
  }

  /// Creates a Mealy ``StateMachine`` with an identifier and an initial state.
  /// - Parameters:
  ///   - id: the identifier used to reference this state machine in composite configurations
  ///   - initial: the initial state of the ``StateMachine``
  public init<ID>(id: ID.Type, initial: some State<SuperState>) {
    self.id = ObjectIdentifier(id)
    self.initial = initial
  }

  // MARK: - Typealiases

  // MARK: Public

  public typealias AnyState = any State<SuperState>
  public typealias AnyEvent = any Event<SuperEvent>
  public typealias GuardFunction = @Sendable (AnyState, AnyEvent) async -> Bool
  public typealias MealyTransitionFunction = @Sendable (AnyState, AnyEvent) async
    -> MealyTransition<SuperState, SuperEvent>?

  /// Stable metadata for the route selected during transition resolution.
  public struct RouteDiagnostic: Sendable, Equatable {
    public let stateTypeName: String
    public let eventTypeName: String
    public let declarationOrder: Int

    init(stateTypeName: String, eventTypeName: String, declarationOrder: Int) {
      self.stateTypeName = stateTypeName
      self.eventTypeName = eventTypeName
      self.declarationOrder = declarationOrder
    }
  }

  public struct ResolvedTransition: Sendable {
    public let transition: MealyTransition<SuperState, SuperEvent>
    public let diagnostic: RouteDiagnostic
  }

  // MARK: - Properties

  // MARK: Internal

  let id: ObjectIdentifier?
  let initial: AnyState
  var mealyTable: [TypesIdentifier: [MealyTransitionFunction]] = [:]
  var routeDiagnostics: [TypesIdentifier: [RouteDiagnostic]] = [:]
  var nextRouteDeclarationOrder = 0
  var compositesByState: [ObjectIdentifier: [AnyCompositeDefinition<SuperState, SuperEvent>]] = [:]

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
    register(
      oneOfStates: oneOfStates,
      oneOfEvents: oneOfEvents,
      guard: `guard`,
      mealyTransition: mealyTransition
    )
  }

  /// Registers a pure route without requiring callers to introduce `async`
  /// into guards or transition factories. Existing asynchronous DSL overloads
  /// remain the compatibility surface for decisions that really must suspend.
  public func when<S: State<SuperState>, E: Event<SuperEvent>>(
    state: S.Type,
    on event: E.Type,
    synchronously guard: (@Sendable (S, E) -> Bool)? = nil,
    mealyTransition: @Sendable @escaping (S, E) -> MealyTransition<SuperState, SuperEvent>
  ) -> Self {
    let asynchronousGuard: (@Sendable (S, E) async -> Bool)?
    if let `guard` {
      asynchronousGuard = { state, event in `guard`(state, event) }
    } else {
      asynchronousGuard = nil
    }
    return when(
      state: state,
      on: event,
      guard: asynchronousGuard,
      mealyTransition: { state, event in mealyTransition(state, event) }
    )
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
    await resolveTransition(state: state, event: event)?.transition
  }

  /// Resolves a transition together with metadata identifying the first route
  /// that matched. This is useful for focused diagnostics without changing the
  /// first-match semantics of the runtime.
  public func resolveTransition(
    state: some State<SuperState>,
    event: some Event<SuperEvent>
  ) async -> ResolvedTransition? {
    let identifier = TypesIdentifier(lhsValue: state, rhsValue: event)
    guard let mealyTransitions = mealyTable[identifier] else { return nil }
    let diagnostics = routeDiagnostics[identifier] ?? []
    for (index, transition) in mealyTransitions.enumerated() {
      if let result = await transition(state, event), result.isPerformable {
        let diagnostic = diagnostics.indices.contains(index)
          ? diagnostics[index]
          : RouteDiagnostic(
            stateTypeName: String(reflecting: type(of: state)),
            eventTypeName: String(reflecting: type(of: event)),
            declarationOrder: index
          )
        return ResolvedTransition(transition: result, diagnostic: diagnostic)
      }
    }
    return nil
  }

  // MARK: Internal route registration

  func registering(whens: [When<SuperState, SuperEvent>]) -> Self {
    var machine = self
    for when in whens {
      for route in when.mealyTransitions {
        machine = machine.register(
          oneOfStates: when.oneOfStates,
          oneOfEvents: route.oneOfEvents,
          guard: nil,
          mealyTransition: route.transitionFunction
        )
      }

      for composite in when.compositeDefinitions {
        for state in when.oneOfStates.orderedStates {
          machine.compositesByState[state, default: []].append(composite)
        }
      }
    }
    return machine
  }

  private func register(
    oneOfStates: OneOfStates<SuperState>,
    oneOfEvents: OneOfEvents<SuperEvent>,
    guard: GuardFunction?,
    mealyTransition: @escaping MealyTransitionFunction
  ) -> Self {
    var machine = self
    for state in oneOfStates.orderedStates {
      for event in oneOfEvents.orderedEvents {
        let identifier = TypesIdentifier(lhsIdentifier: state, rhsIdentifier: event)
        let transition: MealyTransitionFunction = { anyState, anyEvent in
          guard oneOfStates.contains(state: anyState), oneOfEvents.contains(event: anyEvent) else {
            return nil
          }
          if let `guard`, !(await `guard`(anyState, anyEvent)) {
            return nil
          }
          return await mealyTransition(anyState, anyEvent)
        }
        machine.mealyTable[identifier, default: []].append(transition)
        machine.routeDiagnostics[identifier, default: []].append(
          RouteDiagnostic(
            stateTypeName: oneOfStates.typeName(for: state),
            eventTypeName: oneOfEvents.typeName(for: event),
            declarationOrder: machine.nextRouteDeclarationOrder
          )
        )
        machine.nextRouteDeclarationOrder += 1
      }
    }
    return machine
  }
}
