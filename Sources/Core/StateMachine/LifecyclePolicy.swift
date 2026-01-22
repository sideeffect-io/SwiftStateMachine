import Foundation

public struct LifecyclePolicy: Sendable {

  public enum Policy: Sendable {
    case never
    case onFailure
    case onCompletion
    case always
  }

  public enum Termination: Sendable {
    case finished
    case failed(Error)
  }

  public static var none: Self {
    Self(policy: .never)
  }

  public static func restartOnFailure(
    maxRestarts: Int? = nil,
    delay: (@Sendable (Int) async -> Void)? = nil
  ) -> Self {
    Self(
      policy: .onFailure,
      maxRestarts: maxRestarts,
      delay: delay
    )
  }

  public static func restartOnCompletion(
    maxRestarts: Int? = nil,
    delay: (@Sendable (Int) async -> Void)? = nil
  ) -> Self {
    Self(
      policy: .onCompletion,
      maxRestarts: maxRestarts,
      delay: delay
    )
  }

  public static func restartAlways(
    maxRestarts: Int? = nil,
    delay: (@Sendable (Int) async -> Void)? = nil
  ) -> Self {
    Self(
      policy: .always,
      maxRestarts: maxRestarts,
      delay: delay
    )
  }

  public init(
    policy: Policy,
    maxRestarts: Int? = nil,
    delay: (@Sendable (Int) async -> Void)? = nil
  ) {
    self.policy = policy
    self.maxRestarts = maxRestarts
    self.delay = delay
  }

  let policy: Policy
  let maxRestarts: Int?
  let delay: (@Sendable (Int) async -> Void)?
  func shouldRestart(after termination: Termination, restartCount: Int) -> Bool {
    if let maxRestarts, restartCount >= maxRestarts {
      return false
    }

    switch (policy, termination) {
    case (.never, _):
      return false
    case (.onFailure, .failed):
      return true
    case (.onCompletion, .finished):
      return true
    case (.always, _):
      return true
    default:
      return false
    }
  }
}
