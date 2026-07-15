/// ``OneOfEvents`` allows to wraps several ``Event`` types into a single entity
/// so that we can create a transition that is valid for those events without having to
/// duplicates the transitions.
public struct OneOfEvents<SuperEvent>: Sendable, Equatable {
  let events: Set<ObjectIdentifier>
  let orderedEvents: [ObjectIdentifier]
  let typeNames: [ObjectIdentifier: String]

  /// Creates a ``OneOfEvents`` from a variadic ``Event`` types parameter
  /// - Parameter events: a list of ``Event`` types
  public init(_ events: any Event<SuperEvent>.Type...) {
    self.init(events)
  }

  /// Creates a ``OneOfEvents`` from a sequence of ``Event`` types
  /// - Parameter events: a sequence of ``Event`` types
  public init(_ events: some Sequence<any Event<SuperEvent>.Type>) {
    let types = Array(events)
    var seen = Set<ObjectIdentifier>()
    orderedEvents = types.compactMap { type in
      let identifier = ObjectIdentifier(type)
      return seen.insert(identifier).inserted ? identifier : nil
    }
    self.events = Set(orderedEvents)
    typeNames = types.reduce(into: [:]) { names, type in
      names[ObjectIdentifier(type)] = String(reflecting: type)
    }
  }

  /// Returns whether the event is part of the set of ``Event`` types
  /// - Parameter event: the ``Event`` instance to test against the set of ``Event`` types
  /// - Returns: true if the ``Event`` instance is part of the set ``Event`` types, false otherwise
  func contains(event: some Event<SuperEvent>) -> Bool {
    events.contains(ObjectIdentifier(type(of: event)))
  }

  func typeName(for event: ObjectIdentifier) -> String {
    typeNames[event] ?? String(describing: event)
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.events == rhs.events
  }
}
