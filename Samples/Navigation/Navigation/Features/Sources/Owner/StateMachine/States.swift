import OwnerDomain
import StateMachineCore

// MARK: - OwnerState

public struct OwnerState: Equatable, Sendable {
  public let isLoading: Bool
  public let owner: Owner
}

// MARK: - OwnerIsIdle

public struct OwnerIsIdle: State {
  public let superState = OwnerState(isLoading: false, owner: .empty)

  public init() { }
}

// MARK: - OwnerIsLoading

public struct OwnerIsLoading: State {
  public let superState = OwnerState(isLoading: true, owner: .empty)

  public init() { }
}

// MARK: - OwnerIsLoaded

public struct OwnerIsLoaded: State {
  let owner: Owner
  public var superState: OwnerState {
    OwnerState(isLoading: false, owner: owner)
  }

  public init(owner: Owner) {
    self.owner = owner
  }

  public var description: String {
    "OwnerIsLoaded (id: \(owner.id))"
  }
}
