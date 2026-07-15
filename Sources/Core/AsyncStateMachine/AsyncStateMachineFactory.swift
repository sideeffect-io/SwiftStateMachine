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
    let cell = OnceCell<BuiltAsyncStateMachine<SuperState, SuperEvent>>()

    return {
      cell.getOrCreate {
        let asyncStateMachine = build()
        return (
          asyncStateMachine: asyncStateMachine,
          erasedAsyncStateMachine: asyncStateMachine
            .share(replayCount: .max(count: 1))
            .eraseToAsyncNonThrowingSequence()
        )
      }
    }
  }
}

/// A synchronous single-flight cell. Construction happens while the lock is
/// held, so concurrent callers cannot observe or build competing singleton
/// state machines.
private final class OnceCell<Value: Sendable>: @unchecked Sendable {
  private let storage = OSAllocatedUnfairLock<Value?>(initialState: nil)

  func getOrCreate(_ build: @Sendable () -> Value) -> Value {
    storage.withLock { storedValue in
      if let storedValue { return storedValue }
      let builtValue = build()
      storedValue = builtValue
      return builtValue
    }
  }
}
