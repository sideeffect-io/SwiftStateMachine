import HomeDomain
import StateMachineCore

public struct HomeState: State, Hashable, Sendable {
  public let section: Section

  public var superState: Self {
    Self(section: section)
  }

  public var description: String {
    "HomeState (\(section))"
  }
}
