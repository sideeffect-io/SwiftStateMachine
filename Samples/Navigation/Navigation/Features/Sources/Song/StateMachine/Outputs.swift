import SongDomain
import StateMachineCore

public struct LoadSong {
  // swiftformat:disable:next wrapAttributes
  let loadFunction: @Sendable (String) async throws -> Song

  public init(loadFunction: @Sendable @escaping (String) async throws -> Song) {
    self.loadFunction = loadFunction
  }

  func callAsFunction(songId: String) -> @Sendable () async -> (any Event<SongEvent>)? {
    {
      do {
        let song = try await loadFunction(songId)
        return DidSucceedToLoad(song: song)
      } catch {
        return nil
      }
    }
  }
}
