// MARK: - Output

/// An ``Output`` wraps a side effect function that can access shared states to perform business work. The side effect can return
/// a stream of any ``Event`` (events being part of the state machine input alphabet) that will be given back to a ``StateMachine``.
/// An ``Output`` can have an execution priority and a lifecycle, it can be cancelled when certain conditions are met.
public struct Output<SuperState, SuperEvent>: Sendable {

  // MARK: - Lifecycle

  // MARK: Public

  /// Creates an ``Output`` from a side effect function that returns a stream of ``Event``. A cancellation policy can be provided.
  /// The ``Output`` can emit a stream of ``Event`` in the long run.
  /// - Parameters:
  ///   - priority: the priority used by the supporting Task. If nil, the priority will be inherited from the parent task
  ///   - sideEffect: the closure that performs the ``Output`` business and sends events over time
  ///   - lifecycle: the cancellation strategy. If none is provided then the side effect will execute until its natural end
  public init<S: AsyncSequence>(
    priority: TaskPriority? = nil,
    sideEffect: @Sendable @escaping () async -> S,
    lifecycle: Cancel<SuperState, SuperEvent>? = nil
  ) where S: Sendable, S.Element == any Event<SuperEvent> {
    self.priority = priority
    self.sideEffect = { await sideEffect().eraseToAsyncNonThrowingSequence() }
    self.lifecycle = lifecycle
  }

  /// Creates an ``Output`` from a side effect function that returns an optional ``Event``. A cancellation policy can be provided.
  /// If the ``Event`` is not nil, it will be wrapped into an ``AsyncSequence`` that returns only this value.
  /// If the ``Event`` is nil, it will be wrapped into an ``AsyncSequence`` that immediately finishes.
  /// - Parameters:
  ///   - priority: the priority used by the supporting Task. If nil, the priority will be inherited from the parent task
  ///   - sideEffect: the closure that performs the ``Output`` business
  ///   - lifecycle: the cancellation strategy. If none is provided then the side effect will execute until its natural end
  public init(
    priority: TaskPriority? = nil,
    sideEffect: @Sendable @escaping () async -> (any Event<SuperEvent>)?,
    lifecycle: Cancel<SuperState, SuperEvent>? = nil
  ) {
    self.priority = priority
    self.sideEffect = { AsyncNonThrowingSequence(factory: sideEffect) }
    self.lifecycle = lifecycle
  }

  // MARK: - Properties

  // MARK: Internal

  let priority: TaskPriority?
  let sideEffect: @Sendable () async -> AsyncNonThrowingSequence<any Event<SuperEvent>>
  let lifecycle: Cancel<SuperState, SuperEvent>?

  // MARK: - Methods

  // MARK: Puvlic

  public func lifecycle(cancel: Cancel<SuperState, SuperEvent>) -> Output<SuperState, SuperEvent> {
    Self(priority: priority, sideEffect: sideEffect, lifecycle: cancel)
  }
}
