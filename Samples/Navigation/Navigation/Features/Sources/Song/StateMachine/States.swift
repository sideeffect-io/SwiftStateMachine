import SongDomain
import StateMachineCore

// MARK: - SongState

public struct SongState: Equatable, Sendable {
  public let isLoading: Bool
  public let song: Song
}

// MARK: - SongIsIdle

public struct SongIsIdle: State {
  public let superState = SongState(isLoading: false, song: .empty)

  public init() { }
}

// MARK: - SongIsLoading

public struct SongIsLoading: State {
  public let superState = SongState(isLoading: true, song: .empty)

  public init() { }
}

// MARK: - SongIsLoaded

public struct SongIsLoaded: State {
  let song: Song
  public var superState: SongState {
    SongState(isLoading: false, song: song)
  }

  public init(song: Song) {
    self.song = song
  }
}
