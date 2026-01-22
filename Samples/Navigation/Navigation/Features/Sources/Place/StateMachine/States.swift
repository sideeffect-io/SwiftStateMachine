import PlaceDomain
import StateMachineCore

// MARK: - PlaceState

public struct PlaceState: Equatable, Sendable {
  public let isLoading: Bool
  public let isError: Bool
  public let place: Place
}

// MARK: - PlaceIsIdle

public struct PlaceIsIdle: State {
  public let superState = PlaceState(
    isLoading: false,
    isError: false,
    place: .empty
  )

  public init() { }
}

// MARK: - PlaceIsLoading

public struct PlaceIsLoading: State {
  public let superState = PlaceState(
    isLoading: true,
    isError: false,
    place: .empty
  )

  public init() { }
}

// MARK: - PlaceIsLoaded

public struct PlaceIsLoaded: State {
  let place: Place

  public var superState: PlaceState {
    PlaceState(
      isLoading: false,
      isError: false,
      place: place
    )
  }

  public init(place: Place) {
    self.place = place
  }

  public var description: String {
    "PlaceIsLoaded (id: \(place.id))"
  }
}

// MARK: - PlaceIsInFailure

public struct PlaceIsInFailure: State {
  public let superState = PlaceState(
    isLoading: false,
    isError: true,
    place: .empty
  )

  public init() { }
}

// MARK: - OwnerIsSelected

public struct OwnerIsSelected: State {
  public let place: Place
  public let ownerId: String

  public var superState: PlaceState {
    PlaceState(
      isLoading: false,
      isError: false,
      place: place
    )
  }

  public init(place: Place, ownerId: String) {
    self.place = place
    self.ownerId = ownerId
  }

  public var description: String {
    "OwnerIsSelected (id: \(ownerId))"
  }
}
