import StateMachineCore

public func makeStateMachine(loadAlbums: LoadAlbums) -> AsyncStateMachine<AlbumsState, AlbumsEvent> {
  AsyncStateMachine(initial: AlbumsAreIdle()) {
    When(states: AlbumsAreIdle.self, AlbumsAreInFailure.self) {
      On(event: DidRequestLoading.self) { _, _ in
        Transition(state: AlbumsAreLoading(previous: []))
        Output(sideEffect: loadAlbums(), lifecycle: Cancel(on: DidRequestLoading.self))
      }
    }

    When(state: AlbumsAreLoading.self) {
      On(event: DidSucceedToLoad.self) { _, event in
        Transition(state: AlbumsAreLoaded(albums: event.albums))
      }

      On(event: DidFailToLoad.self) { _, _ in
        Transition(state: AlbumsAreInFailure())
      }
    }

    When(state: AlbumsAreLoaded.self) {
      On(event: DidRequestLoading.self, guard: { _, event in event.isFullLoading }) { state, _ in
        Transition(state: AlbumsAreLoading(previous: state.albums))
        Output(sideEffect: loadAlbums(), lifecycle: Cancel(on: DidRequestLoading.self))
      }

      On(event: DidRequestLoading.self, guard: { _, event in !event.isFullLoading }) { _, _ in
        Output(sideEffect: loadAlbums(), lifecycle: Cancel(on: DidRequestLoading.self))
      }

      On(event: DidSucceedToLoad.self) { _, event in
        Transition(state: AlbumsAreLoaded(albums: event.albums))
      }

      On(event: DidSelectAlbum.self) { state, event in
        Transition(state: AlbumIsSelected(albums: state.superState.albums, albumId: event.albumId))
      }
    }

    When(state: AlbumIsSelected.self) {
      On(event: DidRequestLoading.self) { state, _ in
        Transition(state: AlbumsAreLoading(previous: state.albums))
        Output(sideEffect: loadAlbums(), lifecycle: Cancel(on: DidRequestLoading.self))
      }
    }
  }
}
