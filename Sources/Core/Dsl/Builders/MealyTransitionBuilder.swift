@resultBuilder
public enum MealyTransitionBuilder<SuperState, SuperEvent> {
  public static func buildExpression(_ output: Output<SuperState, SuperEvent>) -> Output<SuperState, SuperEvent> {
    output
  }

  public static func buildExpression(_ transition: Transition<SuperState>) -> Transition<SuperState> {
    transition
  }

  public static func buildBlock(
    _ transition: Transition<SuperState>,
    _ output: Output<SuperState, SuperEvent>
  ) -> MealyTransition<SuperState, SuperEvent> {
    MealyTransition(transition: transition, output: output)
  }

  public static func buildBlock(_ transition: Transition<SuperState>) -> MealyTransition<SuperState, SuperEvent> {
    MealyTransition(transition: transition, output: nil)
  }

  public static func buildBlock(_ output: Output<SuperState, SuperEvent>) -> MealyTransition<SuperState, SuperEvent> {
    MealyTransition(transition: nil, output: output)
  }
}
