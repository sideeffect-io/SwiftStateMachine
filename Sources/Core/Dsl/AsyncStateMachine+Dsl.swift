extension AsyncStateMachine {
  /// Creates an ``AsyncStateMachine`` directly from a state machine description with a DSL.
  /// Internally it creates the associated ``StateMachine`` structure.
  /// - Parameters:
  ///   - initial: The initial state of the state machine
  ///   - builder: The blocks describing the Mealy transitions
  public convenience init(
    initial: some State<SuperState>,
    @StateMachineBuilder<SuperState, SuperEvent> builder: () -> [When<SuperState, SuperEvent>]
  ) {
    let stateMachine = StateMachine(initial: initial, builder: builder)
    self.init(stateMachine: stateMachine)
  }
}
