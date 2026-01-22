import CheckinStateMachine
import StateMachineCore
import SwiftUI

// MARK: - StateMachineFactoryKey

struct StateMachineFactoryKey: EnvironmentKey {
  // MARK: - Properties

  // MARK: Internal

  static let defaultValue: AsyncStateMachineFactory<CheckinState, CheckinEvent> =
    .default(initial: CheckinState(routes: []))
}

// MARK: - EnvironmentValues + checkinStateMachineFactory

extension EnvironmentValues {
  // MARK: - Properties

  // MARK: Public

  public var checkinStateMachineFactory: AsyncStateMachineFactory<CheckinState, CheckinEvent> {
    get { self[StateMachineFactoryKey.self] }
    set { self[StateMachineFactoryKey.self] = newValue }
  }
}
