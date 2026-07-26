/// A strongly typed reference to a concrete ``State`` type.
///
/// `StateType` enables contextual member syntax in the DSL while preserving
/// the concrete state type inferred by ``When``.
public struct StateType<StateValue: State>: Sendable {
  let type: StateValue.Type

  public init(_ type: StateValue.Type) {
    self.type = type
  }
}

/// A type-erased state reference accepted by ``OneOfStatesBuilder``.
///
/// Result builders intentionally erase grouped states, so their contextual
/// members use this super-state-scoped reference instead of ``StateType``.
public struct StateSetType<SuperState>: Sendable {
  let type: any State<SuperState>.Type

  public init<S: State<SuperState>>(_ type: S.Type) {
    self.type = type
  }
}
