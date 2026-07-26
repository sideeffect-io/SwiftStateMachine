@resultBuilder
public enum OneOfStatesBuilder<SuperState> {
  public static func buildExpression<S: State<SuperState>>(
    _ state: S.Type
  ) -> any State<SuperState>.Type {
    state
  }

  public static func buildExpression(
    _ state: StateSetType<SuperState>
  ) -> any State<SuperState>.Type {
    state.type
  }

  public static func buildBlock(_ states: any State<SuperState>.Type...) -> OneOfStates<SuperState> {
    OneOfStates(states)
  }
}
