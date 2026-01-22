import PlaceDomain
import StateMachineCore

public func makeStateMachine(load: Load) -> AsyncStateMachine<PlaceState, PlaceEvent> {
  AsyncStateMachine(initial: PlaceIsIdle()) {
    When(states: PlaceIsIdle.self, PlaceIsLoaded.self) {
      On(event: DidRequestLoading.self) { _, event in
        Transition(state: PlaceIsLoading())
        Output(sideEffect: load(id: event.id), lifecycle: Cancel(on: DidRequestLoading.self))
      }
    }

    When(state: PlaceIsLoading.self) {
      On(event: DidSucceedToLoad.self) { _, event in
        Transition(state: PlaceIsLoaded(place: event.place))
      }

      On(event: DidFailToLoad.self) { _, _ in
        Transition(state: PlaceIsInFailure())
      }
    }

    When(state: PlaceIsLoaded.self) {
      On(event: DidSelectOwner.self) { state, event in
        Transition(state: OwnerIsSelected(place: state.place, ownerId: event.ownerId))
      }
    }

    When(state: OwnerIsSelected.self) {
      On(event: DidRequestLoading.self) { state, _ in
        Transition(state: PlaceIsLoaded(place: state.place))
      }
    }
  }
}
