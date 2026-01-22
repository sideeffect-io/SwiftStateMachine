import MusicStateMachine
import StateMachineCore
import SwiftUI

// MARK: - StateMachineFactoryKey

struct StateMachineFactoryKey: EnvironmentKey {
  // MARK: - Properties

  // MARK: Internal

  static let defaultValue: AsyncStateMachineFactory<MusicState, MusicEvent> = .default(initial: MusicState(routes: []))
}

// MARK: - EnvironmentValues + musicStateMachineFactory

extension EnvironmentValues {
  // MARK: - Properties

  // MARK: Public

  public var musicStateMachineFactory: AsyncStateMachineFactory<MusicState, MusicEvent> {
    get { self[StateMachineFactoryKey.self] }
    set { self[StateMachineFactoryKey.self] = newValue }
  }
}
