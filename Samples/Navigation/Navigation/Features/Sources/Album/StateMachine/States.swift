import AlbumDomain
import StateMachineCore

// MARK: - AlbumState

public struct AlbumState: Equatable, Sendable {
  public let isLoading: Bool
  public let isError: Bool
  public let album: Album
  public let selectedSongId: String
}

// MARK: - AlbumIsIdle

public struct AlbumIsIdle: State {
  public let superState = AlbumState(
    isLoading: false,
    isError: false,
    album: .empty,
    selectedSongId: ""
  )

  public init() { }
}

// MARK: - AlbumIsLoading

public struct AlbumIsLoading: State {
  public let superState = AlbumState(
    isLoading: true,
    isError: false,
    album: .empty,
    selectedSongId: ""
  )

  public init() { }
}

// MARK: - AlbumIsLoaded

public struct AlbumIsLoaded: State {
  let album: Album

  public var superState: AlbumState {
    AlbumState(
      isLoading: false,
      isError: false,
      album: album,
      selectedSongId: ""
    )
  }

  public init(album: Album) {
    self.album = album
  }

  public var description: String {
    "AlbumIsLoaded (id: \(album.id))"
  }
}

// MARK: - AlbumIsInFailure

public struct AlbumIsInFailure: State {
  public let superState = AlbumState(
    isLoading: false,
    isError: true,
    album: .empty,
    selectedSongId: ""
  )

  public init() { }
}

// MARK: - SongIsSelected

public struct SongIsSelected: State {
  public let album: Album
  public let songId: String

  public var superState: AlbumState {
    AlbumState(
      isLoading: false,
      isError: false,
      album: album,
      selectedSongId: songId
    )
  }

  public init(album: Album, songId: String) {
    self.album = album
    self.songId = songId
  }

  public var description: String {
    "SongIsSelected (id: \(songId))"
  }
}
