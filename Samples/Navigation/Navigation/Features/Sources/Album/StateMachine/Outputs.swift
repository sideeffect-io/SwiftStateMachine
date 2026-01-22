import AlbumDomain
import StateMachineCore

public struct LoadAlbum {
  // swiftformat:disable:next wrapAttributes
  let loadFunction: @Sendable (String) async throws -> Album

  public init(loadFunction: @Sendable @escaping (String) async throws -> Album) {
    self.loadFunction = loadFunction
  }

  func callAsFunction(albumId: String) -> @Sendable () async -> (any Event<AlbumEvent>)? {
    {
      do {
        let album = try await loadFunction(albumId)
        return DidSucceedToLoad(album: album)
      } catch is CancellationError {
        return DidSucceedToLoad(album: .empty)
      } catch {
        return DidFailToLoad()
      }
    }
  }
}
