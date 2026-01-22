import AlbumDomain
import StateMachineCore

public func makeStateMachine(loadAlbum: LoadAlbum) -> AsyncStateMachine<AlbumState, AlbumEvent> {
  AsyncStateMachine(initial: AlbumIsIdle()) {
    When(states: AlbumIsIdle.self, AlbumIsLoaded.self, SongIsSelected.self) {
      On(event: DidRequestLoading.self) { _, event in
        Transition(state: AlbumIsLoading())
        Output(sideEffect: loadAlbum(albumId: event.albumId))
      }
    }

    When(state: AlbumIsLoading.self) {
      On(event: DidSucceedToLoad.self) { _, event in
        Transition(state: AlbumIsLoaded(album: event.album))
      }

      On(event: DidFailToLoad.self) { _, _ in
        Transition(state: AlbumIsInFailure())
      }
    }

    When(states: AlbumIsLoaded.self, SongIsSelected.self) {
      On(event: DidSelectSong.self) { state, event in
        Transition(state: SongIsSelected(album: state.superState.album, songId: event.songId))
      }
    }
  }
}
