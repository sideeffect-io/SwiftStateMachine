import StateMachineCore
import XCTest

// swiftlint:disable type_body_length
// swiftlint:disable function_body_length

final class CompositeTests: XCTestCase, @unchecked Sendable {

  func test_composite_forwards_childEvents_andJoins() async {
    let authRaisedExpectation = expectation(description: "Auth success raised to parent")
    let finishedExpectation = expectation(description: "Root finished after join")

    let asyncStateMachine = AsyncStateMachine<RootSuperState, RootSuperEvent>(initial: RootIdle()) {
      When(state: RootIdle.self) {
        On(event: RootStart.self) { _, _ in
          Transition(state: RootRunning())
        }
      }

      When(state: RootRunning.self) {
        On(event: RootAuthSucceeded.self) { _, _ in
          Transition(state: RootRunning())
        }

        On(event: RootWasSuccessful.self) { _, _ in
          Transition(state: RootFinished())
        }

        Composite {
          StateMachine<AuthSuperState, AuthSuperEvent>(id: AuthMachine.self, initial: AuthIdle()) {
            When(state: AuthIdle.self) {
              On(event: AuthStart.self) { _, _ in
                Transition(state: AuthInProgress())
                Output { AuthSuccess() }
              }
            }

            When(state: AuthInProgress.self) {
              On(event: AuthSuccess.self) { _, _ in
                Transition(state: AuthFinished())
              }
            }
          }

          StateMachine<SyncSuperState, SyncSuperEvent>(id: SyncMachine.self, initial: SyncIdle()) {
            When(state: SyncIdle.self) {
              On(event: SyncStart.self) { _, _ in
                Transition(state: SyncInProgress())
                Output { SyncSuccess() }
              }
            }

            When(state: SyncInProgress.self) {
              On(event: SyncSuccess.self) { _, _ in
                Transition(state: SyncFinished())
              }
            }
          }
        }
        .on(parentEvent: RootStartChildren.self) { _, _ in
          Forward(to: AuthMachine.self, event: AuthStart())
          Forward(to: SyncMachine.self, event: SyncStart())
        }
        .on(childEvent: AuthSuccess.self) { _, _ in
          Raise(event: RootAuthSucceeded())
        }
        .join(whenChildStates: AuthFinished.self, SyncFinished.self) {
          Raise(event: RootWasSuccessful())
        }
      }
    }

    asyncStateMachine.onTransition { _, _, event, newState in
      if event is RootAuthSucceeded {
        authRaisedExpectation.fulfill()
      }

      if newState is RootFinished {
        finishedExpectation.fulfill()
      }
    }

    let task = Task {
      for await _ in asyncStateMachine { }
    }

    asyncStateMachine.send(event: RootStart())
    asyncStateMachine.send(event: RootStartChildren())

    await fulfillment(of: [authRaisedExpectation, finishedExpectation], timeout: 1.0)
    asyncStateMachine.finish()
    task.cancel()
  }

  func test_composite_isInactive_outsideParentState() async {
    let authRaisedExpectation = expectation(description: "Auth success raised to parent")
    authRaisedExpectation.isInverted = true

    let asyncStateMachine = AsyncStateMachine<RootSuperState, RootSuperEvent>(initial: RootIdle()) {
      When(state: RootIdle.self) {
        On(event: RootStart.self) { _, _ in
          Transition(state: RootRunning())
        }
      }

      When(state: RootRunning.self) {
        On(event: RootStop.self) { _, _ in
          Transition(state: RootFinished())
        }

        Composite {
          StateMachine<AuthSuperState, AuthSuperEvent>(id: AuthMachine.self, initial: AuthIdle()) {
            When(state: AuthIdle.self) {
              On(event: AuthStart.self) { _, _ in
                Transition(state: AuthInProgress())
                Output { AuthSuccess() }
              }
            }

            When(state: AuthInProgress.self) {
              On(event: AuthSuccess.self) { _, _ in
                Transition(state: AuthFinished())
              }
            }
          }

          StateMachine<SyncSuperState, SyncSuperEvent>(id: SyncMachine.self, initial: SyncIdle()) {
            When(state: SyncIdle.self) {
              On(event: SyncStart.self) { _, _ in
                Transition(state: SyncInProgress())
                Output { SyncSuccess() }
              }
            }

            When(state: SyncInProgress.self) {
              On(event: SyncSuccess.self) { _, _ in
                Transition(state: SyncFinished())
              }
            }
          }
        }
        .on(parentEvent: RootStartChildren.self) { _, _ in
          Forward(to: AuthMachine.self, event: AuthStart())
          Forward(to: SyncMachine.self, event: SyncStart())
        }
        .on(childEvent: AuthSuccess.self) { _, _ in
          Raise(event: RootAuthSucceeded())
        }
      }
    }

    asyncStateMachine.onTransition { _, _, event, _ in
      if event is RootAuthSucceeded {
        authRaisedExpectation.fulfill()
      }
    }

    let task = Task {
      for await _ in asyncStateMachine { }
    }

    asyncStateMachine.send(event: RootStart())
    asyncStateMachine.send(event: RootStop())
    asyncStateMachine.send(event: RootStartChildren())

    await fulfillment(of: [authRaisedExpectation], timeout: 0.2)
    asyncStateMachine.finish()
    task.cancel()
  }

  func test_composite_join_requiresBothChildren() async {
    let finishedExpectation = expectation(description: "Root finished after join")
    finishedExpectation.isInverted = true

    let asyncStateMachine = AsyncStateMachine<RootSuperState, RootSuperEvent>(initial: RootIdle()) {
      When(state: RootIdle.self) {
        On(event: RootStart.self) { _, _ in
          Transition(state: RootRunning())
        }
      }

      When(state: RootRunning.self) {
        On(event: RootWasSuccessful.self) { _, _ in
          Transition(state: RootFinished())
        }

        Composite {
          StateMachine<AuthSuperState, AuthSuperEvent>(id: AuthMachine.self, initial: AuthIdle()) {
            When(state: AuthIdle.self) {
              On(event: AuthStart.self) { _, _ in
                Transition(state: AuthInProgress())
                Output { AuthSuccess() }
              }
            }

            When(state: AuthInProgress.self) {
              On(event: AuthSuccess.self) { _, _ in
                Transition(state: AuthFinished())
              }
            }
          }

          StateMachine<SyncSuperState, SyncSuperEvent>(id: SyncMachine.self, initial: SyncIdle()) {
            When(state: SyncIdle.self) {
              On(event: SyncStart.self) { _, _ in
                Transition(state: SyncInProgress())
                Output { SyncSuccess() }
              }
            }
          }
        }
        .on(parentEvent: RootStartChildren.self) { _, _ in
          Forward(to: AuthMachine.self, event: AuthStart())
        }
        .join(whenChildStates: AuthFinished.self, SyncFinished.self) {
          Raise(event: RootWasSuccessful())
        }
      }
    }

    asyncStateMachine.onTransition { _, _, event, newState in
      if event is RootWasSuccessful || newState is RootFinished {
        finishedExpectation.fulfill()
      }
    }

    let task = Task {
      for await _ in asyncStateMachine { }
    }

    asyncStateMachine.send(event: RootStart())
    asyncStateMachine.send(event: RootStartChildren())

    await fulfillment(of: [finishedExpectation], timeout: 0.2)
    asyncStateMachine.finish()
    task.cancel()
  }
}

// MARK: - Root

enum RootSuperEvent { }

struct RootSuperState: Equatable {
  let phase: String
}

struct RootIdle: State, Equatable {
  var superState: RootSuperState { RootSuperState(phase: "idle") }
}

struct RootRunning: State, Equatable {
  var superState: RootSuperState { RootSuperState(phase: "running") }
}

struct RootFinished: State, Equatable {
  var superState: RootSuperState { RootSuperState(phase: "finished") }
}

struct RootStart: Event, Equatable {
  typealias SuperEvent = RootSuperEvent
}

struct RootStartChildren: Event, Equatable {
  typealias SuperEvent = RootSuperEvent
}

struct RootAuthSucceeded: Event, Equatable {
  typealias SuperEvent = RootSuperEvent
}

struct RootWasSuccessful: Event, Equatable {
  typealias SuperEvent = RootSuperEvent
}

struct RootStop: Event, Equatable {
  typealias SuperEvent = RootSuperEvent
}

// MARK: - Auth

enum AuthSuperEvent { }

struct AuthSuperState: Equatable {
  let isFinished: Bool
}

struct AuthIdle: State, Equatable {
  var superState: AuthSuperState { AuthSuperState(isFinished: false) }
}

struct AuthInProgress: State, Equatable {
  var superState: AuthSuperState { AuthSuperState(isFinished: false) }
}

struct AuthFinished: State, Equatable {
  var superState: AuthSuperState { AuthSuperState(isFinished: true) }
}

struct AuthStart: Event, Equatable {
  typealias SuperEvent = AuthSuperEvent
}

struct AuthSuccess: Event, Equatable {
  typealias SuperEvent = AuthSuperEvent
}

enum AuthMachine { }

// MARK: - Sync

enum SyncSuperEvent { }

struct SyncSuperState: Equatable {
  let isFinished: Bool
}

struct SyncIdle: State, Equatable {
  var superState: SyncSuperState { SyncSuperState(isFinished: false) }
}

struct SyncInProgress: State, Equatable {
  var superState: SyncSuperState { SyncSuperState(isFinished: false) }
}

struct SyncFinished: State, Equatable {
  var superState: SyncSuperState { SyncSuperState(isFinished: true) }
}

struct SyncStart: Event, Equatable {
  typealias SuperEvent = SyncSuperEvent
}

struct SyncSuccess: Event, Equatable {
  typealias SuperEvent = SyncSuperEvent
}

enum SyncMachine { }
