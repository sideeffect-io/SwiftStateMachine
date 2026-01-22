import OwnerDomain
import StateMachineCore

// MARK: - OwnerEvent

public enum OwnerEvent { }

// MARK: - DidRequestLoading

public struct DidRequestLoading: Event {
  public typealias SuperEvent = OwnerEvent
  let id: String

  public init(id: String) {
    self.id = id
  }
}

// MARK: - DidSucceedToLoad

public struct DidSucceedToLoad: Event {
  public typealias SuperEvent = OwnerEvent
  let owner: Owner
}
