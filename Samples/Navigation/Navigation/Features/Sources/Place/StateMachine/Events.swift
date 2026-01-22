import PlaceDomain
import StateMachineCore

// MARK: - PlaceEvent

public enum PlaceEvent { }

// MARK: - DidRequestLoading

public struct DidRequestLoading: Event {
  public typealias SuperEvent = PlaceEvent

  let id: String

  public init(id: String) {
    self.id = id
  }
}

// MARK: - DidSucceedToLoad

struct DidSucceedToLoad: Event {
  typealias SuperEvent = PlaceEvent

  let place: Place
}

// MARK: - DidFailToLoad

struct DidFailToLoad: Event {
  typealias SuperEvent = PlaceEvent
}

// MARK: - DidSelectOwner

public struct DidSelectOwner: Event {
  public typealias SuperEvent = PlaceEvent

  let ownerId: String

  public init(id: String) {
    ownerId = id
  }
}
