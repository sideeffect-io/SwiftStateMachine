import Foundation

/// Supervises the tasks created for state-machine outputs.
///
/// This actor owns each output task until the task really exits. Cancelling a
/// task only requests cancellation: a side effect which deliberately ignores
/// cancellation remains supervised and therefore cannot be forgotten while it
/// is still capable of doing work.
actor Runtime<SuperState, SuperEvent> {
  deinit {
    tasksInProgress.values.forEach { $0.task.cancel() }
  }

  var tasksInProgress: [UUID: TaskInProgress] = [:]

  @discardableResult
  func execute(
    output: Output<SuperState, SuperEvent>,
    feedback: @Sendable @escaping (any Event<SuperEvent>) async -> Void
  ) -> Task<Void, Never> {
    let id = UUID()
    let task = Task(priority: output.priority) { [output, feedback] in
      var restartCount = 0

      while !Task.isCancelled {
        let eventStream = await output.sideEffect()
        for await event in eventStream {
          guard !Task.isCancelled else { return }
          await feedback(event)
          guard !Task.isCancelled else { return }
        }

        guard !Task.isCancelled else { return }

        if let error = eventStream.failure() {
          guard !(error is CancellationError) else { return }
          if let event = await output.onFailure?(error) {
            guard !Task.isCancelled else { return }
            await feedback(event)
            guard !Task.isCancelled else { return }
          }
          guard output.lifecyclePolicy.shouldRestart(
            after: .failed(error),
            restartCount: restartCount
          ) else { return }
        } else {
          guard output.lifecyclePolicy.shouldRestart(
            after: .finished,
            restartCount: restartCount
          ) else { return }
        }

        let nextRestart = restartCount + 1
        await output.lifecyclePolicy.delay?(nextRestart)
        guard !Task.isCancelled else { return }
        restartCount = nextRestart
      }
    }

    let cancellationPolicy = output.cancellationPolicy
      ?? Cancel(predicate: { _, _, _ in false })
    tasksInProgress[id] = TaskInProgress(
      id: id,
      task: task,
      cancellationPolicy: cancellationPolicy
    )

    return monitor(task: task, id: id)
  }

  /// Cancels every currently supervised output and waits for actual task exit.
  /// This is the terminal shutdown primitive used by `finishAndWait()`.
  func cancelAllAndWait() async {
    let tasks = Array(tasksInProgress.values)
    tasks.forEach { $0.task.cancel() }
    for task in tasks {
      await task.task.value
      tasksInProgress[task.id] = nil
    }
  }

  /// Waits for the currently supervised tasks without requesting cancellation.
  /// This is useful for deterministic shutdown tests and for higher-level
  /// coordinators that have already selected the cancellation policy.
  func waitForAll() async {
    let tasks = Array(tasksInProgress.values)
    for task in tasks {
      await task.task.value
      tasksInProgress[task.id] = nil
    }
  }

  func cancel(
    currentState: some State<SuperState>,
    event: some Event<SuperEvent>,
    newState: (any State<SuperState>)?
  ) async {
    // Snapshot before the first suspension point. An output may finish while
    // its asynchronous cancellation predicate is evaluating, and its monitor
    // then removes it from the actor-owned dictionary.
    let tasks = Array(tasksInProgress.values)
    for task in tasks
      where await task.cancellationPolicy.predicate(currentState, event, newState)
    {
      task.task.cancel()
    }
  }

  /// Requests cancellation but deliberately retains task records until their
  /// worker exits. Use `cancelAllAndWait()` for a terminal barrier.
  func cancelAll() {
    tasksInProgress.values.forEach { $0.task.cancel() }
  }

  @discardableResult
  func execute(
    onInitialStates: [AsyncStateMachine<SuperState, SuperEvent>.OnInitialState],
    id: UUID,
    initialState: some State<SuperState>
  ) -> Task<Void, Never> {
    let task = Task {
      await withTaskGroup(of: Void.self) { group in
        for onInitialState in onInitialStates {
          group.addTask { await onInitialState(id, initialState) }
        }
      }
    }
    let taskID = UUID()
    tasksInProgress[taskID] = TaskInProgress(
      id: taskID,
      task: task,
      cancellationPolicy: Cancel(predicate: { _, _, _ in false })
    )
    return monitor(task: task, id: taskID)
  }

  @discardableResult
  func execute(
    onTransitions: [AsyncStateMachine<SuperState, SuperEvent>.OnTransition],
    id: UUID,
    currentState: some State<SuperState>,
    on event: some Event<SuperEvent>,
    newState: some State<SuperState>
  ) -> Task<Void, Never> {
    let task = Task {
      await withTaskGroup(of: Void.self) { group in
        for onTransition in onTransitions {
          group.addTask {
            await onTransition(id, currentState, event, newState)
          }
        }
      }
    }
    let taskID = UUID()
    tasksInProgress[taskID] = TaskInProgress(
      id: taskID,
      task: task,
      cancellationPolicy: Cancel(predicate: { _, _, _ in false })
    )
    return monitor(task: task, id: taskID)
  }

  private func monitor(task: Task<Void, Never>, id: UUID) -> Task<Void, Never> {
    Task { [weak self] in
      await task.value
      await self?.removeTaskInProgress(id: id)
    }
  }

  private func removeTaskInProgress(id: UUID) {
    tasksInProgress[id] = nil
  }
}
