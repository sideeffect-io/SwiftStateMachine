import AlbumDomain
import Foundation
import StateMachineCore

// MARK: - AlbumEvent

public enum AlbumEvent { }

// MARK: - DidRequestLoading

public struct DidRequestLoading: Event {
  public typealias SuperEvent = AlbumEvent

  let albumId: String

  public init(albumId: String) {
    self.albumId = albumId
  }
}

// MARK: - DidSucceedToLoad

struct DidSucceedToLoad: Event {
  typealias SuperEvent = AlbumEvent

  let album: Album
}

// MARK: - DidFailToLoad

struct DidFailToLoad: Event {
  typealias SuperEvent = AlbumEvent
}

// MARK: - DidSelectSong

public struct DidSelectSong: Event {
  public typealias SuperEvent = AlbumEvent

  let songId: String

  public init(songId: String) {
    self.songId = songId
  }
}
