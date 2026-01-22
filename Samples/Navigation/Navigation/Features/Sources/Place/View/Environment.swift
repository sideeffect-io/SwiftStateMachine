import PlaceStateMachine
import StateMachineCore
import SwiftUI

// MARK: - StateMachineFactory

struct StateMachineFactory: EnvironmentKey {
  // MARK: - Properties

  // MARK: Internal

  static let defaultValue: AsyncStateMachineFactory<PlaceState, PlaceEvent> = .default(initial: PlaceIsIdle())
}

// MARK: - EnvironmentValues + placeStateMachineFactory

extension EnvironmentValues {
  public var placeStateMachineFactory: AsyncStateMachineFactory<PlaceState, PlaceEvent> {
    get { self[StateMachineFactory.self] }
    set { self[StateMachineFactory.self] = newValue }
  }
}
