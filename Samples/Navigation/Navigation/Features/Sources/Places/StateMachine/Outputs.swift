import PlacesDomain
import StateMachineCore

public struct Load {
  // swiftformat:disable:next wrapAttributes
  let loadFunction: @Sendable () async -> [Place]

  public init(loadFunction: @Sendable @escaping () async -> [Place]) {
    self.loadFunction = loadFunction
  }

  func callAsFunction() -> @Sendable () async -> (any Event<PlacesEvent>)? {
    {
      let places = await loadFunction()
      return DidSucceedToLoad(places: places)
    }
  }
}
