import os

/// An ``AsyncStateMachineFactory`` returns a tuple (``AsyncStateMachine``, ``AsyncNonThrowingSequence``).
/// The first property is used by the clients to be able to send events into the async state machine.
/// The second property is a type-erased version of this async state machine. Since we sometimes need to directly return
/// an ``AsyncStateMachine`` and sometimes an ``AsyncShareSequence<AsyncStateMachine>`` and because ``AsyncSequence``
/// is not compatible with primary associated types (yet), we cannot simply return an
/// `any AsyncSequence<any State<SuperState>>`, we have to type erase it (just like Combine does for instance)
typealias BuiltAsyncStateMachine<SuperState, SuperEvent> = (
  asyncStateMachine: AsyncStateMachine<SuperState, SuperEvent>,
  erasedAsyncStateMachine: AsyncNonThrowingSequence<any State<SuperState>>
)

// MARK: - AsyncStateMachineFactory

/// ``AsyncStateMachineFactory`` is a factory class for lazily building an ``AsyncStateMachine`` depending on the
/// wanted lifecycle.
public final class AsyncStateMachineFactory<SuperState, SuperEvent>: Sendable {

  // MARK: - AsyncStateMachineFactory+Lifecycle

  /// A enum that allows to specify the lifecycle of the built ``AsyncStateMachine``
  public enum Lifecycle: Sendable, Equatable {
    /// `.singleton`: only one instance of the ``AsyncStateMachine`` will be built and reused
    case singleton
    /// `.instance`: a new instance of the ``AsyncStateMachine`` will be built on each call to the factory
    case instance
  }

  // MARK: - Lifecycle

  /// Creates an ``AsyncStateMachineFactory`` from a closure building an ``AsyncStateMachine``
  /// - Parameters:
  ///   - lifecycle: the lifecycle of the built ``AsyncStateMachine`` (`Lifecycle.instance` by default)
  ///   - build: the closure that builds the ``AsyncStateMachine``
  public init(
    lifecycle: Lifecycle = .instance,
    build: @Sendable @escaping () -> AsyncStateMachine<SuperState, SuperEvent>
  ) {
    switch lifecycle {
    case .instance:
      self.build = Self.makeInstanceBuildFunction(build: build)
    case .singleton:
      self.build = Self.makeSingletonBuildFunction(build: build)
    }
  }

  // MARK: - Properties

  let build: @Sendable () -> BuiltAsyncStateMachine<SuperState, SuperEvent>

  // MARK: - Methods

  // MARK: Public

  /// Creates a factory that builds an ``AsyncStateMachine`` with an initial state (and no transitions/outputs)
  /// - Parameter initial: the initial state of the ``AsyncStateMachine``
  /// - Returns: The factory that builds the ``AsyncStateMachine`` with the initial state
  public static func `default`(initial: some State<SuperState>) -> AsyncStateMachineFactory<SuperState, SuperEvent> {
    AsyncStateMachineFactory { AsyncStateMachine(initial: initial, builder: { }) }
  }

  // MARK: Private

  private static func makeInstanceBuildFunction(
    build: @Sendable @escaping () -> AsyncStateMachine<SuperState, SuperEvent>
  ) -> @Sendable () -> BuiltAsyncStateMachine<SuperState, SuperEvent> {
    {
      let asyncStateMachine = build()
      return (
        asyncStateMachine: asyncStateMachine,
        erasedAsyncStateMachine: asyncStateMachine.eraseToAsyncNonThrowingSequence()
      )
    }
  }

  private static func makeSingletonBuildFunction(
    build: @Sendable @escaping () -> AsyncStateMachine<SuperState, SuperEvent>
  ) -> @Sendable () -> BuiltAsyncStateMachine<SuperState, SuperEvent> {
    let asyncStateMachineSafeStorage = OSAllocatedUnfairLock<BuiltAsyncStateMachine<SuperState, SuperEvent>?>(
      initialState: nil
    )

    return {
      guard let builtAsyncStateMachine = asyncStateMachineSafeStorage.withLock({ $0 }) else {
        let asyncStateMachine = build()

        let builtAsyncStateMachine = (
          asyncStateMachine: asyncStateMachine,
          erasedAsyncStateMachine: asyncStateMachine
            .share(replayCount: .max(count: 1))
            .eraseToAsyncNonThrowingSequence()
        )
        asyncStateMachineSafeStorage.withLock { $0 = builtAsyncStateMachine }
        return builtAsyncStateMachine
      }

      return builtAsyncStateMachine
    }
  }
}
