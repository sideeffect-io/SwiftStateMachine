import Foundation

actor Runtime<SuperState, SuperEvent> {

  // MARK: - Lifecycle

  // MARK: Internal

  deinit {
    // the Runtime is dealloc, the related state machine does not exist anymore, we can cancel the tasks (side effects/middlewares)
    tasksInProgress.forEach { taskInProgress in
      taskInProgress.task.cancel()
    }
    tasksInProgress.removeAll()
  }

  // MARK: - Properties

  // MARK: Internal

  var tasksInProgress = Set<TaskInProgress>()

  // MARK: - Methods

  // MARK: Internal

  @discardableResult
  func execute(
    output: Output<SuperState, SuperEvent>,
    feedback: @Sendable @escaping (any Event<SuperEvent>) async -> Void
  ) -> Task<Void, Never> {
    // executing the output's side effect in its dedicated task with the expected priority if any.
    // as we are in an actor, the task will inherit the actor's executor
    let task = Task(priority: output.priority) {
      let eventStream = await output.sideEffect()
      for await event in eventStream {
        await feedback(event)
      }
    }

    // resolving the cancellation policy
    let lifecycle = output.lifecycle ?? Cancel(predicate: { _, _, _ in false })

    // storing the task in progress inside our internal storage so we can find it and eventually cancel it later
    let taskInProgress = TaskInProgress(task: task, lifecycle: lifecycle)
    tasksInProgress.update(with: taskInProgress)

    // when the task finishes naturally, then it is removed from the storage
    return Task { [weak self] in
      _ = await task.value
      await self?.removeTaskInProgress(task: taskInProgress)
    }
  }

  func removeTaskInProgress(task: TaskInProgress) {
    tasksInProgress.remove(task)
  }

  func cancel(
    currentState: some State<SuperState>,
    event: some Event<SuperEvent>,
    newState: (any State<SuperState>)?
  ) async {
    for taskInProgress in tasksInProgress
      where await taskInProgress.lifecycle.predicate(currentState, event, newState)
    {
      taskInProgress.task.cancel()
      tasksInProgress.remove(taskInProgress)
    }
  }

  func cancelAll() {
    tasksInProgress.forEach { taskInProgress in
      taskInProgress.task.cancel()
    }
    tasksInProgress.removeAll()
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
          group.addTask {
            await onInitialState(id, initialState)
          }
        }
      }
    }

    let lifecycle = Cancel<SuperState, SuperEvent>(predicate: { _, _, _ in false })

    let taskInProgress = TaskInProgress(task: task, lifecycle: lifecycle)
    tasksInProgress.update(with: taskInProgress)

    return Task { [weak self] in
      _ = await task.value
      await self?.removeTaskInProgress(task: taskInProgress)
    }
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
            await onTransition(
              id,
              currentState,
              event,
              newState
            )
          }
        }
      }
    }

    let lifecycle = Cancel<SuperState, SuperEvent>(predicate: { _, _, _ in false })

    let taskInProgress = TaskInProgress(task: task, lifecycle: lifecycle)
    tasksInProgress.update(with: taskInProgress)

    return Task { [weak self] in
      _ = await task.value
      await self?.removeTaskInProgress(task: taskInProgress)
    }
  }
}
