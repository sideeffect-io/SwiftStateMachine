import Api
import Foundation
import OwnerDomain
import OwnerStateMachine
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

let ownerStateMachineFactory = AsyncStateMachineFactory {
  // build the Output, directly injecting the concrete implementation
  let loadOutput = OwnerStateMachine.Load { id in

    let formatter = PersonNameComponentsFormatter()
    let apiOwner = try await Api.fetchOwner(id: id).owner

    var components = PersonNameComponents()
    components.givenName = apiOwner.firstName
    components.familyName = apiOwner.lastName

    let owner = OwnerDomain.Owner(
      id: apiOwner.id,
      name: formatter.string(from: components),
      age: Int(apiOwner.age)!,
      address: apiOwner.address
    )

    return owner
  }

  // build the state machine, injecting the Output
  let asyncStateMachine = OwnerStateMachine.makeStateMachine(load: loadOutput)

  #if DEBUG
  asyncStateMachine.activateDump()
  #endif

  return asyncStateMachine
}
