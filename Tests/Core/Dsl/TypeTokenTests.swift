import Testing
@testable import StateMachineCore

private struct TokenViewState: Equatable, Sendable {
  let value: Int
}

private enum TokenEvent: Sendable {}

private struct TokenIsIdle: State, Equatable {
  let value: Int
  var superState: TokenViewState { .init(value: value) }
}

private struct TokenIsLoading: State, Equatable {
  let value: Int
  var superState: TokenViewState { .init(value: value) }
}

private struct TokenLoadingWasRequested: Event, Equatable {
  typealias SuperEvent = TokenEvent
  let increment: Int
}

private struct TokenReloadingWasRequested: Event, Equatable {
  typealias SuperEvent = TokenEvent
}

private struct TokenLoadingDidSucceed: Event, Equatable {
  typealias SuperEvent = TokenEvent
  let value: Int
}

private extension StateType where StateValue == TokenIsIdle {
  static var isIdle: Self { .init(TokenIsIdle.self) }
}

private extension StateType where StateValue == TokenIsLoading {
  static var isLoading: Self { .init(TokenIsLoading.self) }
}

private extension EventType where EventValue == TokenLoadingWasRequested {
  static var loadingWasRequested: Self { .init(TokenLoadingWasRequested.self) }
}

private extension EventType where EventValue == TokenReloadingWasRequested {
  static var reloadingWasRequested: Self { .init(TokenReloadingWasRequested.self) }
}

private extension EventType where EventValue == TokenLoadingDidSucceed {
  static var loadingDidSucceed: Self { .init(TokenLoadingDidSucceed.self) }
}

private extension StateSetType where SuperState == TokenViewState {
  static var isIdle: Self { .init(TokenIsIdle.self) }
  static var isLoading: Self { .init(TokenIsLoading.self) }
}

private extension EventSetType where SuperEvent == TokenEvent {
  static var loadingWasRequested: Self { .init(TokenLoadingWasRequested.self) }
  static var reloadingWasRequested: Self { .init(TokenReloadingWasRequested.self) }
}

@Suite("DSL type tokens")
struct TypeTokenTests {
  @Test("When and On preserve concrete closure types")
  func singularTokensPreserveConcreteTypes() async {
    let route = When<TokenViewState, TokenEvent>(state: .isIdle) {
      On(event: .loadingWasRequested) { state, event in
        Transition(state: TokenIsLoading(value: state.value + event.increment))
      }
    }

    let transition = await route.mealyTransitions[0].transitionFunction(
      TokenIsIdle(value: 2),
      TokenLoadingWasRequested(increment: 3)
    )
    let nextState = await transition?.transition?.state()

    #expect(route.oneOfStates == OneOfStates(TokenIsIdle.self))
    #expect(route.mealyTransitions[0].oneOfEvents == OneOfEvents(TokenLoadingWasRequested.self))
    #expect(nextState as? TokenIsLoading == TokenIsLoading(value: 5))
  }

  @Test("Grouped builders accept heterogeneous state and event tokens")
  func groupedBuildersAcceptTokens() {
    let route = When<TokenViewState, TokenEvent> {
      StateSetType<TokenViewState>.isIdle
      StateSetType<TokenViewState>.isLoading
    } transitions: {
      On {
        EventSetType<TokenEvent>.loadingWasRequested
        EventSetType<TokenEvent>.reloadingWasRequested
      } transition: { _, _ in
        Transition(state: TokenIsLoading(value: 0))
      }
    }

    #expect(route.oneOfStates == OneOfStates(TokenIsIdle.self, TokenIsLoading.self))
    #expect(
      route.mealyTransitions[0].oneOfEvents
        == OneOfEvents(TokenLoadingWasRequested.self, TokenReloadingWasRequested.self)
    )
  }

  @Test("Grouped variadic overloads preserve leading-dot syntax")
  func groupedVariadicOverloadsAcceptTokens() {
    let route = When<TokenViewState, TokenEvent>(states: .isIdle, .isLoading) {
      On(events: .loadingWasRequested, .reloadingWasRequested) { _, _ in
        Transition(state: TokenIsLoading(value: 0))
      }
    }

    #expect(route.oneOfStates == OneOfStates(TokenIsIdle.self, TokenIsLoading.self))
    #expect(
      route.mealyTransitions[0].oneOfEvents
        == OneOfEvents(TokenLoadingWasRequested.self, TokenReloadingWasRequested.self)
    )
  }

  @Test("Legacy metatype syntax remains source compatible")
  func legacyMetatypesRemainSupported() {
    let route = When<TokenViewState, TokenEvent>(state: TokenIsLoading.self) {
      On(event: TokenLoadingDidSucceed.self) { _, event in
        Transition(state: TokenIsLoading(value: event.value))
      }
    }

    #expect(route.oneOfStates == OneOfStates(TokenIsLoading.self))
    #expect(route.mealyTransitions[0].oneOfEvents == OneOfEvents(TokenLoadingDidSucceed.self))
  }
}
