@resultBuilder
public enum OneOfEventsBuilder<SuperEvent> {
  public static func buildBlock(_ events: any Event<SuperEvent>.Type...) -> OneOfEvents<SuperEvent> {
    OneOfEvents(events)
  }
}
