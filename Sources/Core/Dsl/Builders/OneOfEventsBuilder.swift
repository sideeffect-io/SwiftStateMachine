@resultBuilder
public enum OneOfEventsBuilder<SuperEvent> {
  public static func buildExpression<E: Event<SuperEvent>>(
    _ event: E.Type
  ) -> any Event<SuperEvent>.Type {
    event
  }

  public static func buildExpression(
    _ event: EventSetType<SuperEvent>
  ) -> any Event<SuperEvent>.Type {
    event.type
  }

  public static func buildBlock(_ events: any Event<SuperEvent>.Type...) -> OneOfEvents<SuperEvent> {
    OneOfEvents(events)
  }
}
