import MusicDomain
import StateMachineCore
import SwiftUI

public struct MusicState: StateMachineCore.State, Equatable, Sendable {
  public let routes: [Route]
  public let popup: Popup?

  public var superState: Self {
    self
  }

  public init(routes: [Route], popup: Popup? = nil) {
    self.routes = routes
    self.popup = popup
  }

  public var description: String {
    "MusicState (routes: \(routes), popup: \(String(describing: popup)))"
  }
}
