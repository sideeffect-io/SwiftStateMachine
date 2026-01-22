import OwnerDomain
import StateMachineCore

public struct Load {
  let loadFunction: @Sendable (String) async throws -> Owner

  public init(loadFunction: @Sendable @escaping (String) async throws -> Owner) {
    self.loadFunction = loadFunction
  }

  func callAsFunction(id: String) -> @Sendable () async -> (any Event<OwnerEvent>)? {
    {
      do {
        let owner = try await loadFunction(id)
        return DidSucceedToLoad(owner: owner)
      } catch {
        return nil
      }
    }
  }
}
