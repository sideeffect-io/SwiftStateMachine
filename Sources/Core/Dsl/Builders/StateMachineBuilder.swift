@resultBuilder
public enum StateMachineBuilder<SuperState, SuperEvent> {
  public static func buildBlock(_ whens: When<SuperState, SuperEvent>...) -> [When<SuperState, SuperEvent>] {
    whens
  }
}
