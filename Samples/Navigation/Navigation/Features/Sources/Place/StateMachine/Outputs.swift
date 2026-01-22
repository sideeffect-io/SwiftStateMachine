import PlaceDomain
import StateMachineCore

public struct Load {
  let loadFunction: @Sendable (String) async throws -> Place

  public init(loadFunction: @Sendable @escaping (String) async throws -> Place) {
    self.loadFunction = loadFunction
  }

  func callAsFunction(id: String) -> @Sendable () async -> (any Event<PlaceEvent>)? {
    {
      do {
        let place = try await loadFunction(id)
        return DidSucceedToLoad(place: place)
      } catch is CancellationError {
        return DidSucceedToLoad(place: .empty)
      } catch {
        return DidFailToLoad()
      }
    }
  }
}
