import Foundation
import HomeDomain
import StateMachineCore

// MARK: - HomeEvent

public enum HomeEvent { }

// MARK: - DidSelectSection

public struct DidSelectSection: Event {
  public typealias SuperEvent = HomeEvent

  let section: Section
  public init(section: Section) {
    self.section = section
  }
}

// MARK: - DidReceiveDeepLink

public struct DidReceiveDeepLink: Event {
  public typealias SuperEvent = HomeEvent
  let url: URL

  public init(url: URL) {
    self.url = url
  }
}
