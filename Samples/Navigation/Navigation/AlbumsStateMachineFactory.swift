import AlbumsDomain
import AlbumsStateMachine
import Api
import MusicStateMachine
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

let albumsStateMachineFactory = AsyncStateMachineFactory {
  // build the Output, injecting the domain
  let loadAlbumsOutput = AlbumsStateMachine.LoadAlbums {
    // fetch data from the API
    let response = try await Api.fetchAlbums()
    return response.albums.map {
      AlbumsDomain.Album(id: $0.id, title: $0.title, author: $0.author, numberOfSongs: $0.songs.count)
    }
  }

  // build the state machine, injecting the Output
  let asyncStateMachine = AlbumsStateMachine.makeStateMachine(loadAlbums: loadAlbumsOutput)

  // attach the state machine to the music mediator
  asyncStateMachine.connectAsSender(to: musicMediator, whenNewState: AlbumIsSelected.self) { _, _, newState in
    DidRequestAddingRoutes(routes: .album(id: newState.albumId))
  }

  #if DEBUG
  asyncStateMachine.activateDump()
  #endif

  return asyncStateMachine
}
