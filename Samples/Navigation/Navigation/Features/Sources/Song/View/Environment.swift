import SongStateMachine
import StateMachineCore
import SwiftUI

// MARK: - StateMachineFactory

struct StateMachineFactory: EnvironmentKey {
  // MARK: - Properties

  // MARK: Internal
  static let defaultValue: AsyncStateMachineFactory<SongState, SongEvent> = .default(initial: SongIsIdle())
}

// MARK: - EnvironmentValues + songStateMachineFactory

extension EnvironmentValues {
  public var songStateMachineFactory: AsyncStateMachineFactory<SongState, SongEvent> {
    get { self[StateMachineFactory.self] }
    set { self[StateMachineFactory.self] = newValue }
  }
}
