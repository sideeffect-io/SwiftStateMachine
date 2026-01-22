import OwnerStateMachine
import StateMachineCore
import SwiftUI

// MARK: - StateMachineFactory

struct StateMachineFactory: EnvironmentKey {
  // MARK: - Properties

  // MARK: Internal
  static let defaultValue: AsyncStateMachineFactory<OwnerState, OwnerEvent> = .default(initial: OwnerIsIdle())
}

// MARK: - EnvironmentValues + ownerStateMachineFactory

extension EnvironmentValues {
  public var ownerStateMachineFactory: AsyncStateMachineFactory<OwnerState, OwnerEvent> {
    get { self[StateMachineFactory.self] }
    set { self[StateMachineFactory.self] = newValue }
  }
}
