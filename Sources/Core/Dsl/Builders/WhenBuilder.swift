@resultBuilder
public enum WhenBuilder<S, SuperState, SuperEvent> {
  public static func buildExpression(_ on: On<S, SuperState, SuperEvent>) -> On<S, SuperState, SuperEvent> {
    on
  }

  public static func buildBlock(_ ons: On<S, SuperState, SuperEvent>...) -> [On<S, SuperState, SuperEvent>] {
    ons
  }
}
