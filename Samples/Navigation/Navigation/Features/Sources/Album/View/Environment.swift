import AlbumStateMachine
import StateMachineCore
import SwiftUI

// MARK: - StateMachineFactory

struct StateMachineFactory: EnvironmentKey {
  // MARK: - Properties

  // MARK: Internal

  static let defaultValue: AsyncStateMachineFactory<AlbumState, AlbumEvent> = .default(initial: AlbumIsIdle())
}

// MARK: - EnvironmentValues + albumStateMachineFactory

extension EnvironmentValues {
  public var albumStateMachineFactory: AsyncStateMachineFactory<AlbumState, AlbumEvent> {
    get { self[StateMachineFactory.self] }
    set { self[StateMachineFactory.self] = newValue }
  }
}
