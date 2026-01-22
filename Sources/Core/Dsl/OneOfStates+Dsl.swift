extension OneOfStates {
  public init(@OneOfStatesBuilder<SuperState> builder: () -> OneOfStates) {
    self = builder()
  }
}
