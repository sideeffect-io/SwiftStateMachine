import StateMachineCore

public func makeStateMachine(loadSong: LoadSong) -> AsyncStateMachine<SongState, SongEvent> {
  AsyncStateMachine(initial: SongIsIdle()) {
    When(states: SongIsIdle.self, SongIsLoaded.self) {
      On(event: DidRequestLoading.self) { _, event in
        Transition(state: SongIsLoading())
        Output(sideEffect: loadSong(songId: event.songId))
      }
    }

    When(state: SongIsLoading.self) {
      On(event: DidSucceedToLoad.self) { _, event in
        Transition(state: SongIsLoaded(song: event.song))
      }
    }
  }
}
