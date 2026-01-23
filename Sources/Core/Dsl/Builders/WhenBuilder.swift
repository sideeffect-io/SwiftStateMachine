@resultBuilder
public enum WhenBuilder<S, SuperState, SuperEvent> {
  public static func buildExpression(
    _ on: On<S, SuperState, SuperEvent>
  ) -> WhenComponent<S, SuperState, SuperEvent> {
    .on(on)
  }

  public static func buildExpression<C1SuperState, C1SuperEvent, C2SuperState, C2SuperEvent>(
    _ composite: Composite<SuperState, SuperEvent, C1SuperState, C1SuperEvent, C2SuperState, C2SuperEvent>
  ) -> WhenComponent<S, SuperState, SuperEvent> {
    .composite(composite.eraseToAny())
  }

  public static func buildBlock(
    _ components: WhenComponent<S, SuperState, SuperEvent>...
  ) -> [WhenComponent<S, SuperState, SuperEvent>] {
    components
  }
}
