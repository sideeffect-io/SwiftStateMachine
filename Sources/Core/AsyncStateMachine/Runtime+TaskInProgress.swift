import Foundation

extension Runtime {
  struct TaskInProgress: Hashable {
    init(task: Task<Void, Never>, lifecycle: Cancel<SuperState, SuperEvent>) {
      id = UUID()
      self.task = task
      self.lifecycle = lifecycle
    }

    let id: UUID
    let task: Task<Void, Never>
    let lifecycle: Cancel<SuperState, SuperEvent>

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
