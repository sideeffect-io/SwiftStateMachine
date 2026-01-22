import CheckinDomain
import StateMachineCore

public struct CheckinState: State, Equatable, Sendable {
  public let routes: [Route]

  public var superState: Self {
    self
  }

  public init(routes: [Route]) {
    self.routes = routes
  }

  public var description: String {
    "CheckinState (routes: \(routes))"
  }
}
