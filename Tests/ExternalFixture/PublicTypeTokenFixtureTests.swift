import StateMachineCore
import Testing

private struct FixtureState: Equatable, Sendable {}
private enum FixtureEvent: Sendable {}

private struct FixtureIsIdle: State, Equatable {
  let superState = FixtureState()
}

private struct FixtureIsLoading: State, Equatable {
  let superState = FixtureState()
}

private struct FixtureLoadingWasRequested: Event, Equatable {
  typealias SuperEvent = FixtureEvent
}

private extension StateType where StateValue == FixtureIsIdle {
  static var isIdle: Self { .init(FixtureIsIdle.self) }
}

private extension EventType where EventValue == FixtureLoadingWasRequested {
  static var loadingWasRequested: Self {
    .init(FixtureLoadingWasRequested.self)
  }
}

@Test("Public DSL supports contextual state and event tokens")
func publicDSLTypeTokens() async {
  let machine = AsyncStateMachine<FixtureState, FixtureEvent>(initial: FixtureIsIdle()) {
    When(state: .isIdle) {
      On(event: .loadingWasRequested) { _, _ in
        Transition(state: FixtureIsLoading())
      }
    }
  }

  await machine.sendAndWait(
    event: FixtureLoadingWasRequested(),
    until: .transitionCommitted
  )

  #expect(machine.lastKnownState is FixtureIsLoading)
  await machine.finishAndWait()
}
