import MusicDomain
import StateMachineCore
import SwiftUI

// MARK: - MusicEvent

public enum MusicEvent { }

// MARK: - DidRequestResettingRoutes

public struct DidRequestResettingRoutes: Event, Sendable {
  public typealias SuperEvent = MusicEvent
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
  public typealias SuperEvent = MusicEvent
  let routes: [Route]

  public init(routes: Route...) {
    self.routes = routes
  }

  public var description: String {
    "DidRequestAddingRoutes (\(routes))"
  }
}

// MARK: - DidRequestSettingPopup

public struct DidRequestSettingPopup: Event {
  public typealias SuperEvent = MusicEvent
  let popup: Popup

  public init(popup: Popup) {
    self.popup = popup
  }

  public var description: String {
    "DidRequestSettingPopup (\(popup))"
  }
}

// MARK: - DidRequestResettingPopup

public struct DidRequestResettingPopup: Event {
  public typealias SuperEvent = MusicEvent
  public init() { }
}

// MARK: - DidReceiveDeepLink

public struct DidReceiveDeepLink: Event {
  public typealias SuperEvent = MusicEvent

  let url: URL
  public init(url: URL) {
    self.url = url
  }
}
