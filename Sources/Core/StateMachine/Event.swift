// MARK: - Event

/// https://en.wikipedia.org/wiki/Finite-state_machine
/// (see the mathematical section, where Events can be seen as the Alphabet of a State Machine)
/// ``Event`` stands for the actions that can be sent to a ``StateMachine``.
/// An ``Event`` belongs to a finite set of Events. We use the associatedtype ``SuperEvent`` to constrain the belonging to that set.
public protocol Event<SuperEvent>: Sendable, CustomStringConvertible {
  associatedtype SuperEvent
}

// MARK: CustomStringConvertible

extension Event {
  public var description: String {
    "\(type(of: self))"
  }
}
