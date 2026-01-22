// MARK: - State

/// https://en.wikipedia.org/wiki/Finite-state_machine (see the mathematical section)
/// ``State`` stands for the elements of the finite set of States that a ``StateMachine`` can handle.
/// As a ``State`` belongs to a finite set of States, we use the associatedtype ``SuperState`` to constrain the belonging to that set.
/// Unlike ``Event`` where the associatedtype is only used as a constraint,
/// a ``SuperState`` property has to be derived from the concrete ``State`` implementation.
/// Our experience shows that declarative UIs like SwiftUI work better when provided with an aggregated/equatable state that can be seen
/// as a UIState where all the properties are already computed (and not recomputed everytime the view renders), and that can optimize
/// the rendering process.
public protocol State<SuperState>: Sendable, CustomStringConvertible {
  associatedtype SuperState

  var superState: SuperState { get }
}

// MARK: CustomStringConvertible

extension State {
  public var description: String {
    "\(type(of: self))"
  }
}
