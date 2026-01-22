import Foundation

/// A ``UIStateMachine`` is a wrapper around an ``AsyncStateMachine``. Once started, it publishes the result
/// of the state machine's transitions, either in the form of the SuperState or a UIState resulting from a mapping.
/// As a consequence of `UIState` being ``Equatable``, the published values are distinct.
/// As an ``AsyncStateMachine`` is a unicast async sequence, ``UIStateMachine`` is protected against mutiple starts.
/// Once the ``UIStateMachine`` is deallocated the task supporting the ``AsyncStateMachine`` iteration is canceled.
@MainActor
public final class UIStateMachine<UIState, SuperEvent>: ObservableObject, Sendable where UIState: Equatable & Sendable {
  // MARK: - Lifecycle

  // MARK: Public

  /// Creates a ``UIStateMachine`` from an ``AsyncStateMachine`` and a mapping function from `SuperState` to a `UIState`
  /// - Parameters:
  ///   - asyncStateMachine: The ``AsyncStateMachine`` that will be used to execute the state machine
  ///   - mapping: The function transforming the `SuperState` to a `UIState`
  public convenience init<SuperState>(
    asyncStateMachine: AsyncStateMachine<SuperState, SuperEvent>,
    mapping: @Sendable @escaping (SuperState) -> UIState
  ) where SuperState: Sendable {
    self.init(
      asyncStateMachineFactory: AsyncStateMachineFactory<SuperState, SuperEvent> { asyncStateMachine },
      mapping: mapping
    )
  }

  /// Creates a ``UIStateMachine`` from an ``AsyncStateMachineFactory``
  /// and a mapping function from `SuperState` to a `UIState`
  /// - Parameters:
  ///   - asyncStateMachineFactory: The ``AsyncStateMachineFactory`` that will be used to build the state machine
  ///   - mapping: The function transforming the `SuperState` to a `UIState`
  public init<SuperState>(
    asyncStateMachineFactory: AsyncStateMachineFactory<SuperState, SuperEvent>,
    mapping: @Sendable @escaping (SuperState) -> UIState
  ) where SuperState: Sendable {
    let (asyncStateMachine, erasedAsyncStateMachine) = asyncStateMachineFactory.build()

    state = mapping(asyncStateMachine.lastKnownState.superState)
    send = { @Sendable (event: any Event<SuperEvent>) in asyncStateMachine.send(event: event) }
    sendAndWait = { event in await asyncStateMachine.sendAndWait(event: event) }
    uiStateSequence = erasedAsyncStateMachine
      .map { $0.superState }
      .map(mapping)
      .eraseToAsyncNonThrowingSequence()
  }

  /// Creates a ``UIStateMachine`` from an ``AsyncStateMachine``.
  /// - Parameter asyncStateMachine: The ``AsyncStateMachine`` that will be used to execute the state machine
  public convenience init(
    asyncStateMachine: AsyncStateMachine<UIState, SuperEvent>
  ) {
    self.init(
      asyncStateMachineFactory: AsyncStateMachineFactory<UIState, SuperEvent> { asyncStateMachine }
    )
  }

  /// Creates a ``UIStateMachine`` from an ``AsyncStateMachineFactory``.
  /// - Parameter asyncStateMachine: The ``AsyncStateMachine`` that will be used to build the state machine
  public init(
    asyncStateMachineFactory: AsyncStateMachineFactory<UIState, SuperEvent>
  ) {
    let (asyncStateMachine, erasedAsyncStateMachine) = asyncStateMachineFactory.build()

    state = asyncStateMachine.lastKnownState.superState
    send = { @Sendable (event: any Event<SuperEvent>) in asyncStateMachine.send(event: event) }
    sendAndWait = { event in await asyncStateMachine.sendAndWait(event: event) }
    uiStateSequence = erasedAsyncStateMachine
      .map { $0.superState }
      .eraseToAsyncNonThrowingSequence()
  }

  // MARK: - Properties

  // MARK: Public

  @Published
  public private(set) var state: UIState
  nonisolated public let send: @Sendable (any Event<SuperEvent>) -> Void
  nonisolated public let sendAndWait: @Sendable (any Event<SuperEvent>) async -> Void

  // MARK: Internal

  let uiStateSequence: AsyncNonThrowingSequence<UIState>
  var uiStateSequenceTask: Task<Void, Never>?

  #if DEBUG
  var onStart: (@Sendable () -> Void)?
  var onStop: (@Sendable () -> Void)?
  #endif

  // MARK: - Methods

  // MARK: Public

  /// Starts the iteration of the internal ``AsyncStateMachine`` and publishes the result in the `state` property.
  /// This function is protected against concurrent ``AsyncStateMachine`` iterations.
  /// The iteration will be canceled when the ``UIStateMachine`` is deallocated.
  public func start() {
    guard uiStateSequenceTask == nil else { return }

    #if DEBUG
    onStart?()
    #endif

    uiStateSequenceTask = Task { [weak self] in
      #if DEBUG
      defer { self?.onStop?() }
      #endif
      var iterator = self?.uiStateSequence.makeAsyncIterator()
      while let uiState = await iterator?.next() {
        if uiState != self?.state {
          self?.state = uiState
        }
      }
    }

  }

  deinit {
    uiStateSequenceTask?.cancel()
    uiStateSequenceTask = nil
  }
}
