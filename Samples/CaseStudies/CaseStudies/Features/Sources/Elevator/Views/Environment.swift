import StateMachineCore
import SwiftUI

// MARK: - ElevatorStateMachineKey

public struct ElevatorStateMachineKey: EnvironmentKey {
  // MARK: - Properties

  // MARK: Public

  public static let defaultValue: AsyncStateMachineFactory<ElevatorState, ElevatorEvent> =
    .default(initial: ElevatorIsOpen(persons: 1))
}

// MARK: - EnvironmentValues + elevatorStateMachineFactory

extension EnvironmentValues {
  public var elevatorStateMachineFactory: AsyncStateMachineFactory<ElevatorState, ElevatorEvent> {
    get { self[ElevatorStateMachineKey.self] }
    set { self[ElevatorStateMachineKey.self] = newValue }
  }
}
