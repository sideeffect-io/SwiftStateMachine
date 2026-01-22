import PlacesDomain
import StateMachineCore

// MARK: - PlacesEvent

public enum PlacesEvent { }

// MARK: - DidRequestLoading

public struct DidRequestLoading: Event {
  public typealias SuperEvent = PlacesEvent
  let isFullLoading: Bool

  public init(isFullLoading: Bool) {
    self.isFullLoading = isFullLoading
  }
}

// MARK: - DidSucceedToLoad

public struct DidSucceedToLoad: Event {
  public typealias SuperEvent = PlacesEvent
  let places: [Place]
}

// MARK: - DidSelectPlace

public struct DidSelectPlace: Event {
  public typealias SuperEvent = PlacesEvent
  let id: String

  public init(id: String) {
    self.id = id
  }
}
