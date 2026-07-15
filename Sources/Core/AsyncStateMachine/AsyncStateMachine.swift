import Foundation
import os
import StateMachineShared

/// An independently running Mealy state-machine runtime which exposes its state
/// changes as a unicast `AsyncSequence`.
///
/// Sending an event starts the command runtime even when no state observer is
/// installed. Iteration is therefore an observation concern only; it no longer
/// controls transition execution or side-effect ownership.
public final class AsyncStateMachine<SuperState, SuperEvent>: AsyncSequence, Sendable {
  // MARK: Public types

  public typealias AnyState = any State<SuperState>
  public typealias AnyEvent = any Event<SuperEvent>
  public typealias Element = AnyState
  public typealias AsyncIterator = Iterator
  public typealias OnLifecycleEvent = @Sendable (LifecycleEvent) async -> Void

  /// Selects the synchronization point used by `sendAndWait(event:until:)`.
  public enum SendCompletion: Sendable {
    /// The event has been evaluated and any resulting state has been committed.
    case transitionCommitted
    /// The matching output has completed, including any configured restarts.
    case outputFinished
  }

  // MARK: Package types

  package typealias OnInitialState = @Sendable (UUID, AnyState) async -> Void
  package typealias OnTransition = @Sendable (UUID, AnyState, AnyEvent, AnyState) async -> Void
  package typealias OnDeinit = @Sendable (UUID) -> Void

  // MARK: Internal types

  struct EventToken: @unchecked Sendable {
    let event: AnyEvent
    let completion: SendCompletionToken?
  }

  final class SendCompletionToken: @unchecked Sendable {
    private struct Storage {
      var continuation: CheckedContinuation<Void, Never>?
      var hasResumed = false
    }

    let point: SendCompletion
    private let storage = OSAllocatedUnfairLock(initialState: Storage())

    init(point: SendCompletion) {
      self.point = point
    }

    /// Installs the caller continuation after cancellation handling has been
    /// registered. If cancellation or terminal completion won that race, the
    /// continuation is resumed immediately after releasing the lock.
    func install(_ continuation: CheckedContinuation<Void, Never>) {
      let shouldResume = storage.withLock { state in
        guard !state.hasResumed else { return true }
        state.continuation = continuation
        return false
      }
      if shouldResume {
        continuation.resume()
      }
    }

    func resume() {
      let continuation = storage.withLock { state -> CheckedContinuation<Void, Never>? in
        guard !state.hasResumed else { return nil }
        state.hasResumed = true
        defer { state.continuation = nil }
        return state.continuation
      }
      continuation?.resume()
    }
  }

  // MARK: Lifecycle

  public init(stateMachine: StateMachine<SuperState, SuperEvent>) {
    self.stateMachine = stateMachine
    id = UUID()
    eventStream = AsyncUnicastChannel<EventToken>()
    stateStream = AsyncUnicastChannel<AnyState>()
    currentState = SendableStorage(value: nil)
    runtime = Runtime<SuperState, SuperEvent>()
    onInitialStates = SendableStorage(value: [])
    onTransitions = SendableStorage(value: [])
    onDeinits = SendableStorage(value: [])
    shouldLog = SendableStorage(value: true)
    lifecycleDispatcher = LifecycleDispatcher()

    if !stateMachine.compositesByState.isEmpty {
      let eventStream = eventStream
      compositeCoordinator = CompositeCoordinator(
        sendToParent: { event in
          _ = eventStream.send(EventToken(event: event, completion: nil))
        },
        compositesByState: stateMachine.compositesByState
      )
    } else {
      compositeCoordinator = nil
    }

    execution = MachineExecution(
      stateMachine: stateMachine,
      eventStream: eventStream,
      stateStream: stateStream,
      currentState: currentState,
      runtime: runtime,
      onInitialStates: onInitialStates,
      onTransitions: onTransitions,
      shouldLog: shouldLog,
      compositeCoordinator: compositeCoordinator,
      lifecycleDispatcher: lifecycleDispatcher,
      id: id
    )
  }

  deinit {
    execution.abort()
    execution.enqueueDeinit(onDeinits.get())
  }

  // MARK: Public properties

  public let stateMachine: StateMachine<SuperState, SuperEvent>
  public let id: UUID

  /// Either the initial state or the state most recently committed by the
  /// independently running command loop.
  public var lastKnownState: AnyState {
    currentState.get() ?? stateMachine.initial
  }

  // MARK: Internal properties

  let eventStream: AsyncUnicastChannel<EventToken>
  let stateStream: AsyncUnicastChannel<AnyState>
  let currentState: SendableStorage<AnyState?>
  let runtime: Runtime<SuperState, SuperEvent>
  let onInitialStates: SendableStorage<[OnInitialState]>
  let onTransitions: SendableStorage<[OnTransition]>
  let onDeinits: SendableStorage<[OnDeinit]>
  let shouldLog: SendableStorage<Bool>
  let compositeCoordinator: CompositeCoordinator<SuperState, SuperEvent>?
  let lifecycleDispatcher: LifecycleDispatcher
  let execution: MachineExecution<SuperState, SuperEvent>

  // MARK: Public methods

  public func send(event: some Event<SuperEvent>) {
    execution.startIfNeeded()
    _ = eventStream.send(EventToken(event: event, completion: nil))
  }

  /// Waits until the matching output completes. This preserves the historical
  /// one-argument behavior; use the two-argument overload to wait only for a
  /// state commit.
  public func sendAndWait(event: some Event<SuperEvent>) async {
    await sendAndWait(event: event, until: .outputFinished)
  }

  public func sendAndWait(event: some Event<SuperEvent>, until completion: SendCompletion) async {
    execution.startIfNeeded()
    let token = SendCompletionToken(point: completion)
    await withTaskCancellationHandler(operation: {
      await withCheckedContinuation { continuation in
        token.install(continuation)
        let accepted = eventStream.send(EventToken(event: event, completion: token))
        if !accepted {
          token.resume()
        }
      }
    }, onCancel: {
      // Cancelling a caller ends only its wait. The event remains a normal
      // accepted command and keeps the runtime's ordering guarantees.
      token.resume()
    })
  }

  /// Rejects later events after draining events already accepted by the command
  /// channel. State observation finishes after outputs and composites have been
  /// asked to stop.
  public func finish() {
    execution.startIfNeeded()
    eventStream.finish()
  }

  /// Finishes the machine and waits until all supervised output tasks have
  /// actually exited.
  public func finishAndWait() async {
    await execution.finishAndWait()
  }

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

  @discardableResult
  public func disableLog() -> Self {
    shouldLog.set(value: false)
    return self
  }

  public func makeAsyncIterator() -> Iterator {
    execution.startIfNeeded()
    return Iterator(stateIterator: stateStream.makeAsyncIterator())
  }

  // MARK: Package methods

  @discardableResult
  package func onInitialState(block: @escaping OnInitialState) -> Self {
    onInitialStates.apply { $0.append(block) }
    return self
  }

  @discardableResult
  package func onTransition(block: @escaping OnTransition) -> Self {
    onTransitions.apply { $0.append(block) }
    return self
  }

  @discardableResult
  package func onDeinit(block: @escaping OnDeinit) -> Self {
    onDeinits.apply { $0.append(block) }
    return self
  }
}
