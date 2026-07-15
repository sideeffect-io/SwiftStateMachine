import Foundation

extension Runtime {
  struct TaskInProgress {
    init(id: UUID, task: Task<Void, Never>, cancellationPolicy: Cancel<SuperState, SuperEvent>) {
      self.id = id
      self.task = task
      self.cancellationPolicy = cancellationPolicy
    }

    let id: UUID
    let task: Task<Void, Never>
    let cancellationPolicy: Cancel<SuperState, SuperEvent>

  }
}
