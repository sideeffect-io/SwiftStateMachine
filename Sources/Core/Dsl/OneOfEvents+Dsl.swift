extension OneOfEvents {
  public init(@OneOfEventsBuilder<SuperEvent> builder: () -> OneOfEvents) {
    self = builder()
  }
}
