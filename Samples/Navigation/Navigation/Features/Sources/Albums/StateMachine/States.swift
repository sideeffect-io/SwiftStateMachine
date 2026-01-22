import AlbumsDomain
import StateMachineCore

// MARK: - AlbumsState

public struct AlbumsState: Sendable, Equatable, Hashable {
  public let isFailed: Bool
  public let isLoading: Bool
  public let albums: [Album]
  public let picked: String
}

// MARK: - AlbumsAreIdle

public struct AlbumsAreIdle: State {
  public let superState = AlbumsState(
    isFailed: false,
    isLoading: false,
    albums: [],
    picked: ""
  )

  public init() { }
}

// MARK: - AlbumsAreLoading

public struct AlbumsAreLoading: State {
  let previous: [Album]

  public var superState: AlbumsState {
    AlbumsState(
      isFailed: false,
      isLoading: true,
      albums: previous,
      picked: ""
    )
  }

  public init(previous: [Album]) {
    self.previous = previous
  }
}

// MARK: - AlbumsAreLoaded

public struct AlbumsAreLoaded: State {
  let albums: [Album]

  public var superState: AlbumsState {
    AlbumsState(
      isFailed: false,
      isLoading: false,
      albums: albums,
      picked: ""
    )
  }

  public init(albums: [Album]) {
    self.albums = albums
  }
}

// MARK: - AlbumsAreInFailure

public struct AlbumsAreInFailure: State {
  public let superState = AlbumsState(
    isFailed: true,
    isLoading: false,
    albums: [],
    picked: ""
  )

  public init() { }
}

// MARK: - AlbumIsSelected

public struct AlbumIsSelected: State {
  let albums: [Album]
  public let albumId: String

  public var superState: AlbumsState {
    AlbumsState(
      isFailed: false,
      isLoading: false,
      albums: albums,
      picked: albumId
    )
  }

  public init(albums: [Album], albumId: String) {
    self.albums = albums
    self.albumId = albumId
  }

  public var description: String {
    "AlbumIsSelected (id: \(albumId))"
  }
}
