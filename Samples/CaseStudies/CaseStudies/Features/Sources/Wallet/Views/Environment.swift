import StateMachineCore
import SwiftUI

// MARK: - WalletStateMachineKey

public struct WalletStateMachineKey: EnvironmentKey {
  // MARK: - Properties

  // MARK: Public

  public static let defaultValue: AsyncStateMachineFactory<WalletState, WalletEvent> =
    .default(initial: WalletState(credits: 0))
}

// MARK: - EnvironmentValues + walletStateMachineFactory

extension EnvironmentValues {
  public var walletStateMachineFactory: AsyncStateMachineFactory<WalletState, WalletEvent> {
    get { self[WalletStateMachineKey.self] }
    set { self[WalletStateMachineKey.self] = newValue }
  }
}
