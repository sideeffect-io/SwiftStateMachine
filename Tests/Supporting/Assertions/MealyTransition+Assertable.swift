@testable import StateMachineCore

extension MealyTransition {
  static func makeAssertable(
    transitionTo state: some State<SuperState>,
    emit event: some Event<SuperEvent>
  ) -> Assertable {
    Assertable(state: state, event: event)
  }

  struct Assertable {
    let transitionAssertable: Transition<SuperState>.Assertable
    let outputAssertable: Output<SuperState, SuperEvent>.Assertable

    init(state: some State<SuperState>, event: some Event<SuperEvent>) {
      transitionAssertable = Transition.makeAssertable(state: state)
      outputAssertable = Output.makeAssertable(event: event)
    }

    var transition: Transition<SuperState> {
      transitionAssertable.transition
    }

    var output: Output<SuperState, SuperEvent> {
      outputAssertable.output
    }
  }
}

func XCTAssert<SuperState, SuperEvent>(
  received: MealyTransition<SuperState, SuperEvent>?,
  isFrom assertable: MealyTransition<SuperState, SuperEvent>.Assertable,
  file: StaticString = #filePath,
  line: UInt = #line
) async {
  await XCTAssert(
    received: received?.transition,
    isFrom: assertable.transitionAssertable,
    file: file,
    line: line
  )
  await XCTAssert(
    received: received?.output,
    isFrom: assertable.outputAssertable,
    file: file,
    line: line
  )
}
