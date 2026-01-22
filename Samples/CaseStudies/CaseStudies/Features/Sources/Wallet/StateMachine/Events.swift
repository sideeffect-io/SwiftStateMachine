import StateMachineCore

// MARK: - WalletEvent

public enum WalletEvent { }

// MARK: - DidRequestToAddCreditsEvent

struct DidRequestToAddCreditsEvent: Event {
  typealias SuperEvent = WalletEvent

  let credits: Double
}

// MARK: - DidRequestToRemoveCreditsEvent

struct DidRequestToRemoveCreditsEvent: Event {
  typealias SuperEvent = WalletEvent

  let credits: Double
}
