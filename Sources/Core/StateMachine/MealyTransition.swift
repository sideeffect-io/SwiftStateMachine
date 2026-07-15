public struct MealyTransition<SuperState, SuperEvent>: Sendable {
  public let transition: Transition<SuperState>?
  public let output: Output<SuperState, SuperEvent>?

  /// Creates a Mealy transition containing a state transition, an output, or both.
  public init(
    transition: Transition<SuperState>?,
    output: Output<SuperState, SuperEvent>?
  ) {
    precondition(
      transition != nil || output != nil,
      "A MealyTransition must contain a transition, an output, or both."
    )
    self.transition = transition
    self.output = output
  }

  /// Creates a state-only Mealy transition.
  public init(transition: Transition<SuperState>) {
    self.init(transition: transition, output: nil)
  }

  /// Creates an output-only Mealy transition.
  public init(output: Output<SuperState, SuperEvent>) {
    self.init(transition: nil, output: output)
  }

  var isPerformable: Bool {
    transition != nil || output != nil
  }
}
