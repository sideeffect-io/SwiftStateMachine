@resultBuilder
public enum OneOfStatesBuilder<SuperState> {
  public static func buildBlock(_ states: any State<SuperState>.Type...) -> OneOfStates<SuperState> {
    OneOfStates(states)
  }
}
