import Api
import CheckinStateMachine
import Foundation
import PlaceDomain
import PlaceStateMachine
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

let placeStateMachineFactory = AsyncStateMachineFactory {
  // build the Output, directly injecting the concrete implementation
  let loadOutput = PlaceStateMachine.Load { id in

    let formatter = PersonNameComponentsFormatter()
    let apiPlace = try await Api.fetchPlace(id: id).place

    var components = PersonNameComponents()
    components.givenName = apiPlace.owner.firstName
    components.familyName = apiPlace.owner.lastName

    let place = PlaceDomain.Place(
      id: apiPlace.id,
      name: apiPlace.name,
      address: apiPlace.address,
      telephone: apiPlace.phone,
      description: apiPlace.description,
      owner: Owner(id: apiPlace.owner.id, name: formatter.string(from: components))
    )
    return place
  }

  // build the state machine, injecting the Output
  let asyncStateMachine = PlaceStateMachine.makeStateMachine(load: loadOutput)

  // attach the state machine to the checkin mediator
  asyncStateMachine.connectAsSender(to: checkinMediator, whenNewState: OwnerIsSelected.self) { _, _, newState in
    DidRequestAddingRoutes(routes: .owner(id: newState.ownerId))
  }

  #if DEBUG
  asyncStateMachine.activateDump()
  #endif

  return asyncStateMachine
}
