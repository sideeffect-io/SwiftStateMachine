// swiftlint:disable type_name

/// ``On`` is a building block of the DSL that allows to specify the Mealy transition that should
/// occur given an ``Event`` in the context of a current ``State``.
/// The Mealy transition can eventually by gated by a `guard` statement.
/// This block can be used in the context of a ``When`` building block.
public struct On<S, SuperState, SuperEvent>: Sendable {
  // MARK: - Lifecycle

  // MARK: Public

  /// Creates a ``On`` block given an ``Event`` and a Mealy transition gated by a `guard` statement.
  ///
  /// ```
  /// On(event: LoadingWasRequest.self) { state, event in
  ///   state.value.isEmpty && !event.id.isEmpty
  /// } transition: { state, event in
  ///   Transition(state: Loading(event.id))
  ///   Output(sideEffect: load(event.id))
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - event: The ``Event`` type that will trigger the Mealy transition
  ///   - guard: The `guard` statement gating the Mealy transition
  ///   - transition: The block describing the Mealy transition (optional state transition + optional output)
  public init<E: Event<SuperEvent>>(
    event: E.Type,
    guard: @Sendable @escaping (S, E) async -> Bool = { _, _ in true },
    @MealyTransitionBuilder<SuperState, SuperEvent> transition: @Sendable @escaping (S, E) async
      -> MealyTransition<SuperState, SuperEvent>
  ) {
    oneOfEvents = OneOfEvents(event)
    mealyTransition = { state, anyEvent in
      guard let event = anyEvent as? E else { return nil }
      guard await `guard`(state, event) else { return nil }
      return await transition(state, event)
    }
  }

  /// Creates a ``On`` block given a set of possible ``Event``s and a Mealy transition gated by a `guard` statement.
  ///
  /// ```
  /// On {
  ///   LoadingWasRequested.self
  ///   ReloadingWasRequested.self
  /// } guard: { state, event in
  ///   state.value.isEmpty && !event.id.isEmpty
  /// } transition: { state, event in
  ///   Transition(state: Loading(event.id))
  ///   Output(sideEffect: load(event.id))
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - oneOfEvents: The set of ``Event`` types that will trigger the Mealy transition
  ///   - guard: The `guard` statement gating the Mealy transition
  ///   - transition: The block describing the Mealy transition (optional state transition + optional output)
  public init(
    @OneOfEventsBuilder<SuperEvent> _ oneOfEvents: () -> OneOfEvents<SuperEvent>,
    guard: @Sendable @escaping (S, any Event<SuperEvent>) async -> Bool = { _, _ in true },
    @MealyTransitionBuilder<SuperState, SuperEvent> transition: @Sendable @escaping (S, any Event<SuperEvent>) async
      -> MealyTransition<SuperState, SuperEvent>
  ) {
    let oneOfEvents = oneOfEvents()
    self.oneOfEvents = oneOfEvents
    mealyTransition = { state, anyEvent in
      guard await `guard`(state, anyEvent) else { return nil }
      guard oneOfEvents.contains(event: anyEvent) else { return nil }
      return await transition(state, anyEvent)
    }
  }

  /// Creates a ``On`` block given a set of possible ``Event``s and a Mealy transition gated by a `guard` statement.
  ///
  /// ```
  /// On(events:
  ///   LoadingWasRequested.self,
  ///   ReloadingWasRequested.self
  /// ) { state, event in
  ///   state.value.isEmpty && !event.id.isEmpty
  /// } transition: { state, event in
  ///   Transition(state: Loading(event.id))
  ///   Output(sideEffect: load(event.id))
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - events: The set of ``Event`` types that will trigger the Mealy transition
  ///   - guard: The `guard` statement gating the Mealy transition
  ///   - transition: The block describing the Mealy transition (optional state transition + optional output)
  public init(
    events: any Event<SuperEvent>.Type...,
    guard: @Sendable @escaping (S, any Event<SuperEvent>) async -> Bool = { _, _ in true },
    @MealyTransitionBuilder<SuperState, SuperEvent> transition: @Sendable @escaping (S, any Event<SuperEvent>)
    async -> MealyTransition<SuperState, SuperEvent>
  ) {
    let oneOfEvents = OneOfEvents(events)
    self.oneOfEvents = oneOfEvents
    mealyTransition = { state, anyEvent in
      guard await `guard`(state, anyEvent) else { return nil }
      guard oneOfEvents.contains(event: anyEvent) else { return nil }
      return await transition(state, anyEvent)
    }
  }

  // MARK: - Typealiases

  // MARK: Internal

  typealias AnyState = any State<SuperState>
  typealias AnyEvent = any Event<SuperEvent>

  // MARK: - Properties

  // MARK: Internal

  let oneOfEvents: OneOfEvents<SuperEvent>
  let mealyTransition: @Sendable (S, AnyEvent) async -> MealyTransition<SuperState, SuperEvent>?
}
