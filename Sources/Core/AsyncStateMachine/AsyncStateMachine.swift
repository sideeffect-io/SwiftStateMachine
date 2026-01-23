import Foundation
import StateMachineShared

/// An ``AsyncStateMachine`` is an ``AsyncSequence`` of `any State<SuperState>`. Each event sent to the
/// ``AsyncStateMachine`` is stacked in an ``AsyncUnicastChannel``, waiting to be consumed when the sequence is being iterated over.
/// An ``AsyncStateMachine`` relies on a ``StateMachine`` definition to drive the transitions from one state to another given an event.
/// An ``AsyncStateMachine`` is a UNICAST sequence and can be iterated over inside a SINGLE Task. Iterating within concurrent Tasks is
/// considered a development error. We don't want concurrent transitions to happen since it would be non deterministic.
/// It is possible to iterate over it inside consecutive tasks though (in that case the state is preserved).
/// To allow concurrent iterations, we have 2 possibilities:
/// - Share the sequence output so a single Iterator is created for multiple consumers (soon available in the swift async algorithms repo)
/// - Have a locking mechanism that awaits the current transition to be completed before consuming the next event
/// (https://github.com/sideeffect-io/AsyncStateMachine/blob/main/Sources/Supporting/AsyncSerialSequence.swift)
public final class AsyncStateMachine<SuperState, SuperEvent>: AsyncSequence, Sendable {

  // MARK: - Lifecycle

  // MARK: Public

  /// Creates an ``AsyncStateMachine`` from a ``StateMachine`` definition
  /// - Parameter stateMachine: the ``StateMachine`` that describes the transitions and outputs
  public init(stateMachine: StateMachine<SuperState, SuperEvent>) {
    self.stateMachine = stateMachine
    eventStream = AsyncUnicastChannel<EventToken>()
    currentState = SendableStorage(value: nil)
    runtime = Runtime<SuperState, SuperEvent>()
    onInitialStates = SendableStorage(value: [])
    onTransitions = SendableStorage(value: [])
    onDeinits = SendableStorage(value: [])
    shouldLog = SendableStorage(value: true)

    if !stateMachine.compositesByState.isEmpty {
      let sendToParent: @Sendable (any Event<SuperEvent>) -> Void = { [eventStream] event in
        eventStream.send(EventToken(event: event, continuation: nil))
      }
      compositeCoordinator = CompositeCoordinator(
        sendToParent: sendToParent,
        compositesByState: stateMachine.compositesByState
      )
    } else {
      compositeCoordinator = nil
    }
  }

  deinit {
    for onDeinit in onDeinits.get() {
      onDeinit(id)
    }
  }

  // MARK: - Typealiases

  // MARK: Public

  public typealias AnyState = any State<SuperState>
  public typealias AnyEvent = any Event<SuperEvent>
  public typealias Element = AnyState
  public typealias AsyncIterator = Iterator
  public typealias OnLifecycleEvent = @Sendable (LifecycleEvent) async -> Void

  // MARK: Package

  package typealias OnInitialState = @Sendable (UUID, AnyState) async -> Void
  package typealias OnTransition = @Sendable (UUID, AnyState, AnyEvent, AnyState) async -> Void
  package typealias OnDeinit = @Sendable (UUID) -> Void

  // MARK: Internal

  typealias EventToken = (event: any Event<SuperEvent>, continuation: UnsafeContinuation<Void, Never>?)

  // MARK: - Properties

  // MARK: Public

  public let stateMachine: StateMachine<SuperState, SuperEvent>

  /// Either the initial state if no transition has been executed yet or the current state
  public var lastKnownState: AnyState {
    currentState.get() ?? stateMachine.initial
  }

  public let id = UUID()

  // MARK: Internal

  let eventStream: AsyncUnicastChannel<EventToken>
  let currentState: SendableStorage<AnyState?>
  let runtime: Runtime<SuperState, SuperEvent>
  let onInitialStates: SendableStorage<[OnInitialState]>
  let onTransitions: SendableStorage<[OnTransition]>
  let onDeinits: SendableStorage<[OnDeinit]>
  let shouldLog: SendableStorage<Bool>
  let compositeCoordinator: CompositeCoordinator<SuperState, SuperEvent>?

  // MARK: - Methods

  // MARK: Public

  /// Sends an event into the state machine.
  /// According to this event and the current state, a transition might happen and produce a new state and execute an output.
  /// - Parameter event: the event to apply to the current state
  public func send(event: some Event<SuperEvent>) {
    eventStream.send(EventToken(event: event, continuation: nil))
  }

  /// Sends an event into the state machine.
  /// According to this event and the current state, a transition might happen and produce a new state and execute an output.
  /// The function will resume only when the transition is done and the associated output has been executed.
  /// - Parameter event: the event to apply to the current state
  public func sendAndWait(event: some Event<SuperEvent>) async {
    guard !eventStream.isFinished else { return }
    guard eventStream.hasActiveIterator else {
      eventStream.send(EventToken(event: event, continuation: nil))
      return
    }
    await withUnsafeContinuation { [eventStream] continuation in
      eventStream.send(EventToken(event: event, continuation: continuation))
    }
  }

  /// Finishes the ``AsyncStateMachine``. The ``AsyncSequence`` will finish and all subsequent calls to `send(_:)` will be discarded.
  public func finish() {
    eventStream.finish()
  }

  /// Registers a callback to be executed when the initial state is emitted or when a subsequent transition is executed
  /// When being executed, the block cannot be cancelled, unless current ``AsyncStateMachine`` is deinit.
  /// - Parameter block: the callback to execute on each transition and at initialization
  /// - Returns: the ``AsyncStateMachine`
  @discardableResult
  public func onLifecycleEvent(block: @escaping OnLifecycleEvent) -> Self {
    onInitialState { id, state in
      await block(.initialState(id: id, state: state))
    }

    onTransition { id, oldState, event, newState in
      await block(.transition(id: id, state: oldState, event: event, newState: newState))
    }

    return self
  }

  /// Disables the logging for each transition
  /// - Returns: the ``AsyncStateMachine``
  @discardableResult
  public func disableLog() -> Self {
    shouldLog.set(value: false)
    return self
  }

  public func makeAsyncIterator() -> Iterator {
    Iterator(asyncStateMachine: self)
  }

  // MARK: Package

  /// Registers a callback called when the initial state is emitted
  /// When being executed, the block cannot be cancelled, unless the current ``AsyncStateMachine`` is deinit.
  /// - Parameter block: the callback called with the internal state machine's id and the initial state
  /// - Returns: the ``AsyncStateMachine``
  @discardableResult
  package func onInitialState(block: @escaping OnInitialState) -> Self {
    onInitialStates.apply { values in
      values.append(block)
    }
    return self
  }

  /// Registers a callback to be executed for the tuple current state/event/new state.
  /// When being executed, the block cannot be cancelled, unless current ``AsyncStateMachine`` is deinit.
  /// - Parameter block: the callback to execute on each transition
  /// - Returns: the ``AsyncStateMachine``
  @discardableResult
  package func onTransition(block: @escaping OnTransition) -> Self {
    onTransitions.apply { values in
      values.append(block)
    }
    return self
  }

  /// Registers a callback called when the object is deinit.
  /// - Parameter block: the callback called with the internal state machine's id
  /// - Returns: the ``AsyncStateMachine``
  @discardableResult
  package func onDeinit(block: @escaping OnDeinit) -> Self {
    onDeinits.apply { values in
      values.append(block)
    }
    return self
  }
}
