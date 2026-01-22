// MARK: - Output

/// An ``Output`` wraps a side effect function that can access shared states to perform business work. The side effect can return
/// a stream of any ``Event`` (events being part of the state machine input alphabet) that will be given back to a ``StateMachine``.
/// An ``Output`` can have an execution priority and a cancellation policy, it can be cancelled when certain conditions are met.
public struct Output<SuperState, SuperEvent>: Sendable {

  // MARK: - Lifecycle

  // MARK: Public

  typealias EventStream = SupervisedSequence<any Event<SuperEvent>>

  /// Creates an ``Output`` from a side effect function that returns a stream of ``Event``. A cancellation policy can be provided.
  /// The ``Output`` can emit a stream of ``Event`` in the long run.
  /// - Parameters:
  ///   - priority: the priority used by the supporting Task. If nil, the priority will be inherited from the parent task
  ///   - sideEffect: the closure that performs the ``Output`` business and sends events over time
  ///   - cancellationPolicy: the cancellation strategy. If none is provided then the side effect will execute until its natural end
  ///   - lifecyclePolicy: the lifecycle policy for restarting the side effect if it finishes or fails
  public init<S: AsyncSequence>(
    priority: TaskPriority? = nil,
    sideEffect: @Sendable @escaping () async -> S,
    cancellationPolicy: Cancel<SuperState, SuperEvent>? = nil,
    lifecyclePolicy: LifecyclePolicy = .none,
    onFailure: (@Sendable (Error) async -> (any Event<SuperEvent>)?)? = nil
  ) where S: Sendable, S.Element == any Event<SuperEvent> {
    self.init(
      priority: priority,
      sideEffect: {
        let sequence = await sideEffect()
        return Self.makeSupervisedSequence(from: sequence)
      },
      cancellationPolicy: cancellationPolicy,
      lifecyclePolicy: lifecyclePolicy,
      onFailure: onFailure
    )
  }

  /// Creates an ``Output`` from a side effect function that returns an optional ``Event``. A cancellation policy can be provided.
  /// If the ``Event`` is not nil, it will be wrapped into an ``AsyncSequence`` that returns only this value.
  /// If the ``Event`` is nil, it will be wrapped into an ``AsyncSequence`` that immediately finishes.
  /// - Parameters:
  ///   - priority: the priority used by the supporting Task. If nil, the priority will be inherited from the parent task
  ///   - sideEffect: the closure that performs the ``Output`` business
  ///   - cancellationPolicy: the cancellation strategy. If none is provided then the side effect will execute until its natural end
  ///   - lifecyclePolicy: the lifecycle policy for restarting the side effect if it finishes or fails
  public init(
    priority: TaskPriority? = nil,
    sideEffect: @Sendable @escaping () async -> (any Event<SuperEvent>)?,
    cancellationPolicy: Cancel<SuperState, SuperEvent>? = nil,
    lifecyclePolicy: LifecyclePolicy = .none,
    onFailure: (@Sendable (Error) async -> (any Event<SuperEvent>)?)? = nil
  ) {
    self.init(
      priority: priority,
      sideEffect: {
        SupervisedSequence(base: AsyncJustSequence(sideEffect))
      },
      cancellationPolicy: cancellationPolicy,
      lifecyclePolicy: lifecyclePolicy,
      onFailure: onFailure
    )
  }

  /// Creates an ``Output`` from a throwing side effect that returns an optional ``Event``.
  /// If the ``Event`` is not nil, it will be wrapped into an ``AsyncSequence`` that returns only this value.
  /// If the ``Event`` is nil, it will be wrapped into an ``AsyncSequence`` that immediately finishes.
  /// - Parameters:
  ///   - priority: the priority used by the supporting Task. If nil, the priority will be inherited from the parent task
  ///   - sideEffect: the throwing closure that performs the ``Output`` business
  ///   - cancellationPolicy: the cancellation strategy. If none is provided then the side effect will execute until its natural end
  ///   - lifecyclePolicy: the lifecycle policy for restarting the side effect if it finishes or fails
  public init(
    priority: TaskPriority? = nil,
    sideEffect: @Sendable @escaping () async throws -> (any Event<SuperEvent>)?,
    cancellationPolicy: Cancel<SuperState, SuperEvent>? = nil,
    lifecyclePolicy: LifecyclePolicy = .none,
    onFailure: (@Sendable (Error) async -> (any Event<SuperEvent>)?)? = nil
  ) {
    self.init(
      priority: priority,
      sideEffect: {
        SupervisedSequence(base: AsyncThrowingStream { continuation in
          Task {
            do {
              if let event = try await sideEffect() {
                continuation.yield(event)
              }
              continuation.finish()
            } catch {
              continuation.finish(throwing: error)
            }
          }
        })
      },
      cancellationPolicy: cancellationPolicy,
      lifecyclePolicy: lifecyclePolicy,
      onFailure: onFailure
    )
  }

  // MARK: - Properties

  // MARK: Internal

  let priority: TaskPriority?
  let sideEffect: @Sendable () async -> EventStream
  let cancellationPolicy: Cancel<SuperState, SuperEvent>?
  let lifecyclePolicy: LifecyclePolicy
  let onFailure: (@Sendable (Error) async -> (any Event<SuperEvent>)?)?

  // MARK: - Methods

  // MARK: Puvlic

  public func cancellationPolicy(cancel: Cancel<SuperState, SuperEvent>) -> Output<SuperState, SuperEvent> {
    Self(
      priority: priority,
      sideEffect: sideEffect,
      cancellationPolicy: cancel,
      lifecyclePolicy: lifecyclePolicy,
      onFailure: onFailure
    )
  }

  public func lifecyclePolicy(_ lifecyclePolicy: LifecyclePolicy) -> Output<SuperState, SuperEvent> {
    Self(
      priority: priority,
      sideEffect: sideEffect,
      cancellationPolicy: cancellationPolicy,
      lifecyclePolicy: lifecyclePolicy,
      onFailure: onFailure
    )
  }

  public func onFailure(
    _ onFailure: @Sendable @escaping (Error) async -> (any Event<SuperEvent>)?
  ) -> Output<SuperState, SuperEvent> {
    Self(
      priority: priority,
      sideEffect: sideEffect,
      cancellationPolicy: cancellationPolicy,
      lifecyclePolicy: lifecyclePolicy,
      onFailure: onFailure
    )
  }

  // MARK: - Internal

  init(
    priority: TaskPriority?,
    sideEffect: @Sendable @escaping () async -> EventStream,
    cancellationPolicy: Cancel<SuperState, SuperEvent>?,
    lifecyclePolicy: LifecyclePolicy,
    onFailure: (@Sendable (Error) async -> (any Event<SuperEvent>)?)?
  ) {
    self.priority = priority
    self.sideEffect = sideEffect
    self.cancellationPolicy = cancellationPolicy
    self.lifecyclePolicy = lifecyclePolicy
    self.onFailure = onFailure
  }

  private static func makeSupervisedSequence<S: AsyncSequence>(
    from sequence: S
  ) -> SupervisedSequence<S.Element> where S: Sendable {
    SupervisedSequence(base: sequence)
  }
}
