import PlacesDomain
import PlacesStateMachine
import StateMachineCore
import SwiftUI

// MARK: - StateMachineFactoryKey

struct StateMachineFactoryKey: EnvironmentKey {
  // MARK: - Properties

  // MARK: Internal

  static let defaultValue: AsyncStateMachineFactory<PlacesState, PlacesEvent> = .default(
    initial: PlacesAreLoaded(places: [.fake, .fake])
  )
}

// MARK: - EnvironmentValues + placesStateMachineFactory

extension EnvironmentValues {
  public var placesStateMachineFactory: AsyncStateMachineFactory<PlacesState, PlacesEvent> {
    get { self[StateMachineFactoryKey.self] }
    set { self[StateMachineFactoryKey.self] = newValue }
  }
}
