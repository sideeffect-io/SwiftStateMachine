import StateMachineCore
import XCTest

final class PublicAPIFixtureTests: XCTestCase, @unchecked Sendable {
  struct FeatureState: Sendable, Equatable {}
  enum FeatureEvent: Sendable {}

  struct Idle: State {
    typealias SuperState = FeatureState
    let superState = FeatureState()
  }

  struct Loading: State {
    typealias SuperState = FeatureState
    let superState = FeatureState()
  }

  struct Start: Event {
    typealias SuperEvent = FeatureEvent
  }

  struct Loaded: Event {
    typealias SuperEvent = FeatureEvent
  }

  func test_publicCoreProductSupportsConcreteOutputStreamsAndCompletionPoints() async {
    let stateMachine = StateMachine<FeatureState, FeatureEvent>(initial: Idle())
      .when(state: Idle.self, on: Start.self) { _, _ in
        MealyTransition(
          transition: Transition(state: Loading()),
          output: Output {
            AsyncStream<Loaded> { continuation in
              continuation.yield(Loaded())
              continuation.finish()
            }
          }
        )
      }

    let runtime = AsyncStateMachine(stateMachine: stateMachine)
    await runtime.sendAndWait(event: Start(), until: .transitionCommitted)

    XCTAssertTrue(runtime.lastKnownState is Loading)
    await runtime.finishAndWait()
  }
}
