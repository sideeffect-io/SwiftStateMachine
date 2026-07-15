/// ``OneOfStates`` allows to wraps several ``State`` types into a single entity
/// so that we can create a transition that is valid for those states without having to
/// duplicates the transitions.
public struct OneOfStates<SuperState>: Sendable, Equatable {
  let states: Set<ObjectIdentifier>
  let orderedStates: [ObjectIdentifier]
  let typeNames: [ObjectIdentifier: String]

  /// Creates a ``OneOfStates`` from a variadic ``State`` types parameter
  /// - Parameter states: a list of ``State`` types
  public init(_ states: any State<SuperState>.Type...) {
    self.init(states)
  }

  /// Creates a ``OneOfStates`` from a sequence of ``State`` types
  /// - Parameter states: a sequence of ``State`` types
  public init(_ states: some Sequence<any State<SuperState>.Type>) {
    let types = Array(states)
    var seen = Set<ObjectIdentifier>()
    orderedStates = types.compactMap { type in
      let identifier = ObjectIdentifier(type)
      return seen.insert(identifier).inserted ? identifier : nil
    }
    self.states = Set(orderedStates)
    typeNames = types.reduce(into: [:]) { names, type in
      names[ObjectIdentifier(type)] = String(reflecting: type)
    }
  }

  /// Returns whether the state is part of the set of ``State`` types
  /// - Parameter state: the ``State`` instance to test against the set of ``State`` types
  /// - Returns: true if the ``State`` instance is part of the set ``State`` types, false otherwise
  func contains(state: some State<SuperState>) -> Bool {
    states.contains(ObjectIdentifier(type(of: state)))
  }

  func typeName(for state: ObjectIdentifier) -> String {
    typeNames[state] ?? String(describing: state)
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.states == rhs.states
  }
}
