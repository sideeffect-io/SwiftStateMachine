import StateMachineCore

// MARK: Public

public struct LoadOutput {
  public init(loadFunction: @Sendable @escaping () async throws -> Void) {
    self.loadFunction = loadFunction
  }

  let loadFunction: @Sendable () async throws -> Void

  func callAsFunction() -> @Sendable () async -> (any Event<ClicsEvent>)? {
    {
      do {
        try await loadFunction()
      } catch {
        return nil
      }
      return DidCompleteLoading()
    }
  }
}
