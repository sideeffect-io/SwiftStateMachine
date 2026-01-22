import StateMachineCore
import SwiftUI

// MARK: - ClicsStateMachineKey

public struct ClicsStateMachineKey: EnvironmentKey {
  // MARK: - Properties

  // MARK: Public

  public static let defaultValue: AsyncStateMachineFactory<ClicsState, ClicsEvent> = .default(initial: DataIsIdle())
}

// MARK: - EnvironmentValues + clicsStateMachineFactory

extension EnvironmentValues {
  public var clicsStateMachineFactory: AsyncStateMachineFactory<ClicsState, ClicsEvent> {
    get { self[ClicsStateMachineKey.self] }
    set { self[ClicsStateMachineKey.self] = newValue }
  }
}
