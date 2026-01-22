import AlbumsDomain
import StateMachineCore

public struct LoadAlbums {
  // swiftformat:disable:next wrapAttributes
  let loadFunction: @Sendable () async throws -> [Album]

  public init(loadFunction: @Sendable @escaping () async throws -> [Album]) {
    self.loadFunction = loadFunction
  }

  func callAsFunction() -> @Sendable () async -> (any Event<AlbumsEvent>)? {
    {
      do {
        let albums = try await loadFunction()
        return DidSucceedToLoad(albums: albums)
      } catch is CancellationError {
        return DidSucceedToLoad(albums: [])
      } catch {
        return DidFailToLoad()
      }
    }
  }
}
