import AlbumsStateMachine
import StateMachineCore
import SwiftUI

// MARK: - StateMachineFactoryKey

struct StateMachineFactoryKey: EnvironmentKey {
  // MARK: - Properties

  // MARK: Internal

  static let defaultValue: AsyncStateMachineFactory<AlbumsState, AlbumsEvent> = .default(
    initial: AlbumsAreLoaded(albums: [.fake, .fake])
  )
}

// MARK: - EnvironmentValues + albumsStateMachineFactory

extension EnvironmentValues {
  public var albumsStateMachineFactory: AsyncStateMachineFactory<AlbumsState, AlbumsEvent> {
    get { self[StateMachineFactoryKey.self] }
    set { self[StateMachineFactoryKey.self] = newValue }
  }
}
