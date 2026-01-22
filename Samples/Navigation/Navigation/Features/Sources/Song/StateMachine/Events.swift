import SongDomain
import StateMachineCore

// MARK: - SongEvent

public enum SongEvent { }

// MARK: - DidRequestLoading

public struct DidRequestLoading: Event {
  public typealias SuperEvent = SongEvent
  let songId: String

  public init(songId: String) {
    self.songId = songId
  }
}

// MARK: - DidSucceedToLoad

public struct DidSucceedToLoad: Event {
  public typealias SuperEvent = SongEvent
  let song: Song
}
