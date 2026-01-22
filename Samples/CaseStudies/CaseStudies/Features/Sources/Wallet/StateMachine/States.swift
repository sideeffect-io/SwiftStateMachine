import StateMachineCore

// MARK: - WalletState

public struct WalletState: Equatable, Sendable, State {
  // MARK: - Properties

  public var superState: Self {
    Self(credits: credits)
  }

  public var description: String {
    "WalletState (credits: \(credits))"
  }

  // MARK: Internal

  let credits: Double
}
