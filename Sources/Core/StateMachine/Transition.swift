/// A ``Transition`` represents the next state in regards to a current state and an event.
/// Prefer keeping the state factory pure and side-effect free; use ``Output`` for effects.
public struct Transition<SuperState>: Sendable {
  /// Creates a ``Transition`` to a next state.
  /// - Parameter state: the next state in the context of the transition
  public init(state: some State<SuperState>) {
    self.state = { state }
  }

  /// Creates a ``Transition`` from a state factory.
  /// This factory can be used to perform computations beforehand.
  /// - Parameter factory: the next state factory function
  public init(state: @Sendable @escaping () async -> any State<SuperState>) {
    self.state = state
  }

  // Disabling formatting rule until
  // [SwiftFormat's Issue 1341](https://github.com/nicklockwood/SwiftFormat/issues/1341) is fixed.
  // swiftformat:disable:next wrapAttributes
  public let state: @Sendable () async -> any State<SuperState>
}
