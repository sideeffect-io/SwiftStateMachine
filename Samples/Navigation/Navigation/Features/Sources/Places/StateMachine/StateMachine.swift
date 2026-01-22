import StateMachineCore

public func makeStateMachine(load: Load) -> AsyncStateMachine<PlacesState, PlacesEvent> {
  AsyncStateMachine(initial: PlacesAreIdle()) {
    When(state: PlacesAreIdle.self) {
      On(event: DidRequestLoading.self) { _, _ in
        Transition(state: PlacesAreLoading(previous: []))
        Output(sideEffect: load(), cancellationPolicy: Cancel(on: DidRequestLoading.self))
      }
    }

    When(state: PlacesAreLoading.self) {
      On(event: DidSucceedToLoad.self) { _, event in
        Transition(state: PlacesAreLoaded(places: event.places))
      }
    }

    When(state: PlacesAreLoaded.self) {
      On(event: DidRequestLoading.self, guard: { _, event in event.isFullLoading }) { state, _ in
        Transition(state: PlacesAreLoading(previous: state.places))
        Output(sideEffect: load(), cancellationPolicy: Cancel(on: DidRequestLoading.self))
      }

      On(event: DidRequestLoading.self, guard: { _, event in !event.isFullLoading }) { _, _ in
        Output(sideEffect: load(), cancellationPolicy: Cancel(on: DidRequestLoading.self))
      }

      On(event: DidSucceedToLoad.self) { _, event in
        Transition(state: PlacesAreLoaded(places: event.places))
      }

      On(event: DidSelectPlace.self) { state, event in
        Transition(state: PlaceIsSelected(places: state.superState.places, placeId: event.id))
      }
    }

    When(state: PlaceIsSelected.self) {
      On(event: DidRequestLoading.self) { state, _ in
        Transition(state: PlacesAreLoading(previous: state.places))
        Output(sideEffect: load(), cancellationPolicy: Cancel(on: DidRequestLoading.self))
      }
    }
  }
}
