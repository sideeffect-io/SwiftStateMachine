import StateMachineCore
import SwiftUI

// MARK: - UnitsStateMachineKey

public struct UnitsStateMachineKey: EnvironmentKey {
  // MARK: - Properties

  // MARK: Public

  public static let defaultValue: AsyncStateMachineFactory<UnitsState, UnitsEvent> =
    .default(initial: ValueIsIncreasing(value: 10))
}

// MARK: - EnvironmentValues + unitsStateMachineFactory

extension EnvironmentValues {
  public var unitsStateMachineFactory: AsyncStateMachineFactory<UnitsState, UnitsEvent> {
    get { self[UnitsStateMachineKey.self] }
    set { self[UnitsStateMachineKey.self] = newValue }
  }
}
