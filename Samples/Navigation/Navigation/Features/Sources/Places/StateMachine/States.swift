import PlacesDomain
import StateMachineCore

// MARK: - PlacesState

public struct PlacesState: Sendable {
  public let isLoading: Bool
  public let places: [Place]
  public let picked: String
}

// MARK: - PlacesAreIdle

public struct PlacesAreIdle: State {
  public let superState = PlacesState(
    isLoading: false,
    places: [],
    picked: ""
  )

  public init() { }
}

// MARK: - PlacesAreLoading

public struct PlacesAreLoading: State {
  let previous: [Place]

  public var superState: PlacesState {
    PlacesState(
      isLoading: true,
      places: previous,
      picked: ""
    )
  }

  public init(previous: [Place]) {
    self.previous = previous
  }
}

// MARK: - PlacesAreLoaded

public struct PlacesAreLoaded: State {
  let places: [Place]

  public var superState: PlacesState {
    PlacesState(
      isLoading: false,
      places: places,
      picked: ""
    )
  }

  public init(places: [Place]) {
    self.places = places
  }
}

// MARK: - PlaceIsSelected

public struct PlaceIsSelected: State {
  let places: [Place]
  public let placeId: String

  public var superState: PlacesState {
    PlacesState(
      isLoading: false,
      places: places,
      picked: placeId
    )
  }

  public init(places: [Place], placeId: String) {
    self.places = places
    self.placeId = placeId
  }

  public var description: String {
    "PlaceIsSelected (id: \(placeId))"
  }
}
