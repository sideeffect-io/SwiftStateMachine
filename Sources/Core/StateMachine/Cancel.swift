/// ``Cancel`` allows to create a cancellation policy according to input states and events.
public struct Cancel<SuperState, SuperEvent>: Sendable {
  // MARK: - Lifecycle

  // MARK: Public

  /// Creates a ``Cancel`` policy where the cancellation is confirmed when the input event is of the expected type
  /// and the predicate (if any) is fulfilled.
  /// - Parameters:
  ///   - event: The type of event for which the cancellation is true
  ///   - predicate: The optional predicate to confirm the cancellation. It must return true to confirm the cancellation
  public init<E: Event<SuperEvent>>(
    on _: E.Type,
    predicate: (@Sendable (any State<SuperState>, E, (any State<SuperState>)?) async -> Bool)? = nil
  ) {
    self.predicate = { anycurrentState, anyEvent, anyNewState in
      guard let event = anyEvent as? E else { return false }
      guard let predicate else { return true }
      return await predicate(
        anycurrentState,
        event,
        anyNewState
      )
    }
  }

  /// Creates a ``Cancel`` policy where the cancellation is confirmed when the input current state and event are of the expected types
  /// and the predicate (if any) is fulfilled.
  /// - Parameters:
  ///   - state: The type of current state for which the cancellation is true
  ///   - event: The type of event for which the cancellation is true
  ///   - predicate: The optional predicate to confirm the cancellation. It must return true to confirm the cancellation
  public init<S: State<SuperState>, E: Event<SuperEvent>>(
    whencurrentState _: S.Type,
    on _: E.Type,
    predicate: (@Sendable (S, E, (any State<SuperState>)?) async -> Bool)? = nil
  ) {
    self.predicate = { anycurrentState, anyEvent, anyNewState in
      guard let state = anycurrentState as? S, let event = anyEvent as? E else { return false }
      guard let predicate else { return true }
      return await predicate(
        state,
        event,
        anyNewState
      )
    }
  }

  /// Creates a ``Cancel`` policy where the cancellation is confirmed when the new state is of the expected types
  /// and the predicate (if any) is fulfilled.
  /// - Parameters:
  ///   - state: The type of new state for which the cancellation is true
  ///   - predicate: The optional predicate to confirm the cancellation. It must return true to confirm the cancellation
  public init<S: State<SuperState>>(
    whenNewState _: S.Type,
    predicate: (@Sendable (any State<SuperState>, any Event<SuperEvent>, S) async -> Bool)? = nil
  ) {
    self.predicate = { anycurrentState, anyEvent, anyNewState in
      guard let state = anyNewState as? S else { return false }
      guard let predicate else { return true }
      return await predicate(
        anycurrentState,
        anyEvent,
        state
      )
    }
  }

  /// Creates a ``Cancel`` policy where the cancellation is confirmed when the predicate is fulfilled.
  /// - Parameter predicate: The predicate to confirm the cancellation. It must return true to confirm the cancellation
  public init(predicate: @Sendable @escaping (
    any State<SuperState>,
    any Event<SuperEvent>,
    (any State<SuperState>)?
  ) async -> Bool) {
    self.predicate = predicate
  }

  // MARK: - Properties

  // MARK: Internal

  let predicate: @Sendable (
    any State<SuperState>,
    any Event<SuperEvent>,
    (any State<SuperState>)?
  ) async -> Bool
}
