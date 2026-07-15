import Foundation

/// Serializes lifecycle *events* while allowing the handlers registered for one
/// event to run concurrently. A retained tail task is cleared after it completes,
/// so long-running machines do not retain their full lifecycle history.
actor LifecycleDispatcher {
  private var tail: (id: UUID, task: Task<Void, Never>)?

  func enqueue(_ operation: @Sendable @escaping () async -> Void) {
    let previous = tail?.task
    let id = UUID()
    let task = Task {
      await previous?.value
      guard !Task.isCancelled else { return }
      await operation()
    }
    tail = (id, task)

    Task { [weak self] in
      await task.value
      await self?.removeCompletedTail(id: id)
    }
  }

  func drain() async {
    await tail?.task.value
  }

  private func removeCompletedTail(id: UUID) {
    guard tail?.id == id else { return }
    tail = nil
  }
}
