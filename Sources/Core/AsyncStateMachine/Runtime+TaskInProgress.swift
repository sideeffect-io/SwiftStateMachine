import Foundation

extension Runtime {
  struct TaskInProgress: Hashable {
    init(task: Task<Void, Never>, cancellationPolicy: Cancel<SuperState, SuperEvent>) {
      id = UUID()
      self.task = task
      self.cancellationPolicy = cancellationPolicy
    }

    let id: UUID
    let task: Task<Void, Never>
    let cancellationPolicy: Cancel<SuperState, SuperEvent>

    static func == (
      lhs: Runtime<SuperState, SuperEvent>.TaskInProgress,
      rhs: Runtime<SuperState, SuperEvent>.TaskInProgress
    ) -> Bool {
      lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
  }
}
