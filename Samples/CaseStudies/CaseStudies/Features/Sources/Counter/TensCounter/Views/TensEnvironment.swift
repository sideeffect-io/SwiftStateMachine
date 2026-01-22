import StateMachineCore
import SwiftUI

// MARK: - TensStateMachineKey

public struct TensStateMachineKey: EnvironmentKey {
  // MARK: - Properties

  // MARK: Public

  public static let defaultValue: AsyncStateMachineFactory<TensState, TensEvent> =
    .default(initial: TensState(value: 1))
}

// MARK: - EnvironmentValues + tensStateMachineFactory

extension EnvironmentValues {
  public var tensStateMachineFactory: AsyncStateMachineFactory<TensState, TensEvent> {
    get { self[TensStateMachineKey.self] }
    set { self[TensStateMachineKey.self] = newValue }
  }
}
