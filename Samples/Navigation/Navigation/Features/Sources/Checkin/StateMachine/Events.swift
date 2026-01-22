import CheckinDomain
import StateMachineCore
import SwiftUI

// MARK: - CheckinEvent

public enum CheckinEvent { }

// MARK: - DidRequestResettingRoutes

// swiftformat:disable:next wrapAttributes
public struct DidRequestResettingRoutes: Event, Sendable {
  public typealias SuperEvent = CheckinEvent
  let routes: [Route]

  public init(routes: [Route]) {
    self.routes = routes
  }

  public var description: String {
    "DidRequestResettingRoutes (\(routes))"
  }
}

// MARK: - DidRequestAddingRoutes

public struct DidRequestAddingRoutes: Event {
  public typealias SuperEvent = CheckinEvent
  let routes: [Route]

  public init(routes: Route...) {
    self.routes = routes
  }

  public var description: String {
    "DidRequestAddingRoutes (\(routes))"
  }
}

// MARK: - DidReceiveDeepLink

public struct DidReceiveDeepLink: Event {
  public typealias SuperEvent = CheckinEvent

  let url: URL
  public init(url: URL) {
    self.url = url
  }
}
