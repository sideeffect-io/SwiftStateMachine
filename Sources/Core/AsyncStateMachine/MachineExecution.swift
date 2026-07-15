import Foundation
import os
import StateMachineShared

/// The command runtime deliberately has no reference to `AsyncStateMachine`.
/// This prevents the background command loop from retaining the public wrapper
/// forever while it waits for an event.
final class MachineExecution<SuperState, SuperEvent>: @unchecked Sendable {
  typealias AnyState = any State<SuperState>
  typealias AnyEvent = any Event<SuperEvent>
  typealias EventToken = AsyncStateMachine<SuperState, SuperEvent>.EventToken

  private struct StartState {
    var hasStarted = false
  }

  private let startState = OSAllocatedUnfairLock(initialState: StartState())
  private let terminal = TerminalLatch()

  let stateMachine: StateMachine<SuperState, SuperEvent>
  let eventStream: AsyncUnicastChannel<EventToken>
  let stateStream: AsyncUnicastChannel<AnyState>
  let currentState: SendableStorage<AnyState?>
  let runtime: Runtime<SuperState, SuperEvent>
  let onInitialStates: SendableStorage<[AsyncStateMachine<SuperState, SuperEvent>.OnInitialState]>
  let onTransitions: SendableStorage<[AsyncStateMachine<SuperState, SuperEvent>.OnTransition]>
  let shouldLog: SendableStorage<Bool>
  let compositeCoordinator: CompositeCoordinator<SuperState, SuperEvent>?
  let lifecycleDispatcher: LifecycleDispatcher
  let id: UUID

  init(
    stateMachine: StateMachine<SuperState, SuperEvent>,
    eventStream: AsyncUnicastChannel<EventToken>,
    stateStream: AsyncUnicastChannel<AnyState>,
    currentState: SendableStorage<AnyState?>,
    runtime: Runtime<SuperState, SuperEvent>,
    onInitialStates: SendableStorage<[AsyncStateMachine<SuperState, SuperEvent>.OnInitialState]>,
    onTransitions: SendableStorage<[AsyncStateMachine<SuperState, SuperEvent>.OnTransition]>,
    shouldLog: SendableStorage<Bool>,
    compositeCoordinator: CompositeCoordinator<SuperState, SuperEvent>?,
    lifecycleDispatcher: LifecycleDispatcher,
    id: UUID
  ) {
    self.stateMachine = stateMachine
    self.eventStream = eventStream
    self.stateStream = stateStream
    self.currentState = currentState
    self.runtime = runtime
    self.onInitialStates = onInitialStates
    self.onTransitions = onTransitions
    self.shouldLog = shouldLog
    self.compositeCoordinator = compositeCoordinator
    self.lifecycleDispatcher = lifecycleDispatcher
    self.id = id
  }

  func startIfNeeded() {
    let shouldStart = startState.withLock { state in
      guard !state.hasStarted else { return false }
      state.hasStarted = true
      return true
    }
    guard shouldStart else { return }

    Task { [self] in
      await run()
    }
  }

  func finishAndWait() async {
    startIfNeeded()
    eventStream.finish()
    await terminal.wait()
  }

  func abort() {
    startIfNeeded()
    eventStream.finish()
  }

  func enqueueDeinit(_ callbacks: [AsyncStateMachine<SuperState, SuperEvent>.OnDeinit]) {
    guard !callbacks.isEmpty else { return }
    let terminal = terminal
    let lifecycleDispatcher = lifecycleDispatcher
    let id = id
    Task {
      await terminal.wait()
      await lifecycleDispatcher.enqueue {
        for callback in callbacks {
          callback(id)
        }
      }
    }
  }

  private func run() async {
    let initialState = currentState.get() ?? stateMachine.initial
    currentState.set(value: initialState)
    _ = stateStream.send(initialState)
    await enqueueInitialState(initialState)
    await compositeCoordinator?.handleInitialState(state: initialState)

    var iterator = eventStream.makeAsyncIterator()
    while let token = await iterator.next() {
      await process(token)
    }

    await compositeCoordinator?.deactivateAll()
    await runtime.cancelAllAndWait()
    stateStream.finish()
    await lifecycleDispatcher.drain()
    terminal.finish()
  }

  private func process(_ token: EventToken) async {
    let oldState = currentState.get() ?? stateMachine.initial
    let mealyTransition = await stateMachine.transition(state: oldState, event: token.event)
    let newState = await mealyTransition?.transition?.state()

    await runtime.cancel(currentState: oldState, event: token.event, newState: newState)
    await compositeCoordinator?.handleTransition(
      currentState: oldState,
      event: token.event,
      newState: newState
    )

    if let newState {
      currentState.set(value: newState)
      _ = stateStream.send(newState)
      if shouldLog.get() {
        await log(
          title: "\(SuperState.self)",
          currentState: oldState,
          event: token.event,
          newState: newState
        )
      }
      await enqueueTransition(currentState: oldState, event: token.event, newState: newState)
    }

    if token.completion?.point == .transitionCommitted {
      token.completion?.resume()
    }

    guard let output = mealyTransition?.output else {
      token.completion?.resume()
      return
    }

    let completionTask = await runtime.execute(output: output) { [eventStream] event in
      guard !Task.isCancelled else { return }
      _ = eventStream.send(EventToken(event: event, completion: nil))
    }

    guard token.completion?.point == .outputFinished else { return }
    let completion = token.completion
    Task {
      await completionTask.value
      completion?.resume()
    }
  }

  private func enqueueInitialState(_ state: AnyState) async {
    let callbacks = onInitialStates.get()
    guard !callbacks.isEmpty else { return }
    let id = id
    await lifecycleDispatcher.enqueue {
      await withTaskGroup(of: Void.self) { group in
        for callback in callbacks {
          group.addTask { await callback(id, state) }
        }
      }
    }
  }

  private func enqueueTransition(currentState: AnyState, event: AnyEvent, newState: AnyState) async {
    let callbacks = onTransitions.get()
    guard !callbacks.isEmpty else { return }
    let id = id
    await lifecycleDispatcher.enqueue {
      await withTaskGroup(of: Void.self) { group in
        for callback in callbacks {
          group.addTask { await callback(id, currentState, event, newState) }
        }
      }
    }
  }
}

private final class TerminalLatch: @unchecked Sendable {
  private struct State {
    var isFinished = false
    var waiters: [CheckedContinuation<Void, Never>] = []
  }

  private let state = OSAllocatedUnfairLock(initialState: State())

  func wait() async {
    await withCheckedContinuation { continuation in
      let shouldResume = state.withLock { state in
        guard !state.isFinished else { return true }
        state.waiters.append(continuation)
        return false
      }
      if shouldResume {
        continuation.resume()
      }
    }
  }

  func finish() {
    let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
      guard !state.isFinished else { return [] }
      state.isFinished = true
      defer { state.waiters.removeAll() }
      return state.waiters
    }
    waiters.forEach { $0.resume() }
  }
}
