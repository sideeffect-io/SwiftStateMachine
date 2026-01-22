import Api
import CheckinStateMachine
import FileSystem
import PlacesDomain
import PlacesStateMachine
import PlacesView
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

let placesStateMachineFactory = AsyncStateMachineFactory {
  // build the domain function, injecting concrete implementations
  let loadFunction = PlacesDomain.makeLoad {
    // fetch data from the API
    let response = try await Api.fetchPlaces()
    return response.places.map { Place(id: $0.id, name: $0.name, stars: $0.stars.count) }
  } saveData: { places in
    // save data to the filesystem
    FileSystem.write(entries: places.map { "\($0)" })
  }

  // build the Output, injecting the domain
  let loadOutput = PlacesStateMachine.Load(loadFunction: loadFunction)

  // build the state machine, injecting the Output
  let asyncStateMachine = PlacesStateMachine.makeStateMachine(load: loadOutput)

  // attach the state machine to the checkin mediator
  asyncStateMachine.connectAsSender(to: checkinMediator, whenNewState: PlaceIsSelected.self) { _, _, newState in
    DidRequestAddingRoutes(routes: .place(id: newState.placeId))
  }

  #if DEBUG
  asyncStateMachine.activateDump()
  #endif

  return asyncStateMachine
}
