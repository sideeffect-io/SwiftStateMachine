/// ``OneOfEvents`` allows to wraps several ``Event`` types into a single entity
/// so that we can create a transition that is valid for those events without having to
/// duplicates the transitions.
public struct OneOfEvents<SuperEvent>: Sendable, Equatable {
  let events: Set<ObjectIdentifier>

  /// Creates a ``OneOfEvents`` from a variadic ``Event`` types parameter
  /// - Parameter events: a list of ``Event`` types
  public init(_ events: any Event<SuperEvent>.Type...) {
    self.events = Set(events.map { ObjectIdentifier($0) })
  }

  /// Creates a ``OneOfEvents`` from a sequence of ``Event`` types
  /// - Parameter events: a sequence of ``Event`` types
  public init(_ events: some Sequence<any Event<SuperEvent>.Type>) {
    self.events = Set(events.map { ObjectIdentifier($0) })
  }

  /// Returns whether the event is part of the set of ``Event`` types
  /// - Parameter event: the ``Event`` instance to test against the set of ``Event`` types
  /// - Returns: true if the ``Event`` instance is part of the set ``Event`` types, false otherwise
  func contains(event: some Event<SuperEvent>) -> Bool {
    events.contains(ObjectIdentifier(type(of: event)))
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.events == rhs.events
  }
}
