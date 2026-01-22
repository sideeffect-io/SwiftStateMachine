import Api
import Foundation
import SongDomain
import SongStateMachine
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

let songStateMachineFactory = AsyncStateMachineFactory {
  // build the Output, injecting the domain
  let loadSongOutput = SongStateMachine.LoadSong { id in
    // fetch data from the API
    let response = try await Api.fetchSong(id: id)
    return Song(
      title: response.song.title,
      author: response.song.author,
      duration: response.song.duration
    )
  }

  // build the state machine, injecting the Output
  let asyncStateMachine = SongStateMachine.makeStateMachine(loadSong: loadSongOutput)

  #if DEBUG
  asyncStateMachine.activateDump()
  #endif

  return asyncStateMachine
}
