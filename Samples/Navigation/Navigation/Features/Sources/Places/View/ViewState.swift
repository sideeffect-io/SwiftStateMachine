import Foundation
import PlacesDomain
import PlacesStateMachine

// MARK: - ViewState

public struct ViewState: Equatable {
  struct Star: Equatable, Identifiable {
    let id = UUID()
    let image: String
  }

  struct Place: Equatable, Identifiable {
    let place: PlacesDomain.Place
    let stars: [Star]
    var id: String {
      place.id
    }
  }

  let isLoading: Bool
  let places: [Place]
}

@Sendable
public func toViewState(state: PlacesState) -> ViewState {
  let places = state.places.map { place in
    var stars = [ViewState.Star]()

    for index in 0..<5 {
      let imageName = index < place.stars ? "star.fill" : "star"
      stars.append(ViewState.Star(image: imageName))
    }

    return ViewState.Place(
      place: place,
      stars: stars
    )
  }

  return ViewState(isLoading: state.isLoading, places: places)
}
