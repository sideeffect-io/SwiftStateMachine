/// ``OneOfStates`` allows to wraps several ``State`` types into a single entity
/// so that we can create a transition that is valid for those states without having to
/// duplicates the transitions.
public struct OneOfStates<SuperState>: Sendable, Equatable {
  let states: Set<ObjectIdentifier>

  /// Creates a ``OneOfStates`` from a variadic ``State`` types parameter
  /// - Parameter states: a list of ``State`` types
  public init(_ states: any State<SuperState>.Type...) {
    self.states = Set(states.map { ObjectIdentifier($0) })
  }

  /// Creates a ``OneOfStates`` from a sequence of ``State`` types
  /// - Parameter states: a sequence of ``State`` types
  public init(_ states: some Sequence<any State<SuperState>.Type>) {
    self.states = Set(states.map { ObjectIdentifier($0) })
  }

  /// Returns whether the state is part of the set of ``State`` types
  /// - Parameter state: the ``State`` instance to test against the set of ``State`` types
  /// - Returns: true if the ``State`` instance is part of the set ``State`` types, false otherwise
  func contains(state: some State<SuperState>) -> Bool {
    states.contains(ObjectIdentifier(type(of: state)))
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.states == rhs.states
  }
}
