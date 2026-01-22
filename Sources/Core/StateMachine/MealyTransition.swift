public struct MealyTransition<SuperState, SuperEvent>: Sendable {
  public let transition: Transition<SuperState>?
  let output: Output<SuperState, SuperEvent>?

  var isPerformable: Bool {
    transition != nil || output != nil
  }
}
