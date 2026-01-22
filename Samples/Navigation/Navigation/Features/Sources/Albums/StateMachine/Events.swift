import AlbumsDomain
import StateMachineCore

// MARK: - AlbumsEvent

public enum AlbumsEvent { }

// MARK: - DidRequestLoading

public struct DidRequestLoading: Event {
  public typealias SuperEvent = AlbumsEvent
  let isFullLoading: Bool

  public init(isFullLoading: Bool) {
    self.isFullLoading = isFullLoading
  }
}

// MARK: - DidSucceedToLoad

public struct DidSucceedToLoad: Event {
  public typealias SuperEvent = AlbumsEvent
  let albums: [Album]
}

// MARK: - DidFailToLoad

public struct DidFailToLoad: Event {
  public typealias SuperEvent = AlbumsEvent
}

// MARK: - DidSelectAlbum

public struct DidSelectAlbum: Event {
  public typealias SuperEvent = AlbumsEvent
  let albumId: String

  public init(albumId: String) {
    self.albumId = albumId
  }
}
