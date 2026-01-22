import AlbumDomain
import AlbumStateMachine
import Api
import MusicStateMachine
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

let albumStateMachineFactory = AsyncStateMachineFactory {
  // build the Output, injecting the domain
  let loadAlbumOutput = AlbumStateMachine.LoadAlbum { id in
    // fetch data from the API
    let response = try await Api.fetchAlbum(id: id)
    return Album(
      id: response.album.id,
      title: response.album.title,
      author: response.album.author,
      dateOfRelease: response.album.dateOfRelease,
      producer: response.album.producer,
      songs: response.album.songs.map { Song(id: $0.id, title: $0.title) }
    )
  }

  // build the state machine, injecting the Output
  let asyncStateMachine = AlbumStateMachine.makeStateMachine(loadAlbum: loadAlbumOutput)

  // attach the state machine to the music mediator
  asyncStateMachine.connectAsSender(to: musicMediator, whenNewState: SongIsSelected.self) { _, _, newState in
    DidRequestSettingPopup(popup: .song(id: newState.songId))
  }

  #if DEBUG
  asyncStateMachine.activateDump()
  #endif

  return asyncStateMachine
}
