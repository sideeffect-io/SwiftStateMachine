import StateMachineCore
import StateMachineShared
import StateMachineTest
import XCTest

// MARK: - XCTAssertTests

// swiftlint:disable implicitly_unwrapped_optional

final class XCTAssertTests: XCTestCase {
  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    failIsCalled = false
    spyFail = { [weak self] _, _, _ in
      self?.failIsCalled = true
    }
  }

  override func tearDown() {
    super.tearDown()

    failIsCalled = false
    spyFail = nil
  }

  // MARK: - Properties

  var failIsCalled: Bool!
  var spyFail: ((String, StaticString, UInt) -> Void)!

  private enum TestedStateMachine {
    static let threeTransitions = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition { TestedState.loading }
          Output { TestedEvent.loadingSucceededWithValue1701 }
        }
      }

      When(state: Loading.self) {
        On(event: LoadingHasSucceeded.self) { _, _ in
          Transition(state: TestedState.loaded)
        }
      }

      When(state: Loaded.self) {
        On(event: ReloadingWasRequested.self) { _, _ in
          Transition(state: TestedState.loading)
        }
      }
    }

    static let oneTransition = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle) {
      When(state: Idle.self) {
        On(event: ReloadingWasRequested.self) { _, _ in
          Transition(state: TestedState.loading)
        }
      }
    }
  }

  func test_isEqual_failsWhenNotEquatable() {
    // Given
    struct NotEquatable {
      let value: Int
    }

    // When
    XCTAssertEqual(anyLhs: NotEquatable(value: 1), anyRhs: NotEquatable(value: 1), fail: spyFail)

    // Then
    XCTAssertTrue(failIsCalled, "Expected XCTAssertEqual to fail when values are not equatable.")
  }
}

// MARK: Tests for XCTAssert(asyncStateMachine:)

extension XCTAssertTests {
  func test_assert_whenAllStatesExpected_doesNotFail() async {
    // Given an async state machine

    // When
    await XCTAssert(asyncStateMachine: AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition { TestedState.loading }
          Output { TestedEvent.loadingSucceededWithValue1701 }
        }
      }

      When(state: Loading.self) {
        On(event: LoadingHasSucceeded.self) { _, _ in
          Transition(state: TestedState.loaded)
        }
      }

      When(state: Loaded.self) {
        On(event: ReloadingWasRequested.self) { _, _ in
          Transition(state: TestedState.loading)
        }
      }
    }) { assertions in
      await assertions.assert(state: TestedState.idle, fail: spyFail)

      assertions.send(event: TestedEvent.loadingRequestedWithValue1701)
      await assertions.assert(state: TestedState.loading, fail: spyFail)
      await assertions.assert(state: TestedState.loaded, fail: spyFail)

      assertions.send(event: TestedEvent.reloadingRequestedWithValue1702)
      await assertions.assert(state: TestedState.loading, fail: spyFail)
    }

    // Then
    XCTAssertFalse(failIsCalled, "Expected XCTAssert to succeed when all passed states are expected.")
  }

  func test_assert_whenSomeUnexpectedStates_fails() async {
    // Given an async state machine

    // When
    await XCTAssert(asyncStateMachine: AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition { TestedState.loading }
          Output { TestedEvent.loadingSucceededWithValue1701 }
        }
      }

      When(state: Loading.self) {
        On(event: LoadingHasSucceeded.self) { _, _ in
          Transition(state: TestedState.loaded)
        }
      }

      When(state: Loaded.self) {
        On(event: ReloadingWasRequested.self) { _, _ in
          Transition(state: TestedState.loading)
        }
      }
    }) { assertions in
      await assertions.assert(state: TestedState.idle, fail: spyFail)

      assertions.send(event: TestedEvent.loadingRequestedWithValue1701)
      await assertions.assert(state: Failed(error: MockError()), fail: spyFail)
      await assertions.assert(state: TestedState.loaded, fail: spyFail)

      assertions.send(event: TestedEvent.reloadingRequestedWithValue1702)
      await assertions.assert(state: TestedState.loading, fail: spyFail)
    }

    // Then
    XCTAssertTrue(failIsCalled, "Expected XCTAssert to fail when unexpected states are passed.")
  }

  func test_assert_whenTimeoutIsTriggered_fails() async {
    // Given an async state machine
    let sut = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition { TestedState.loading }
        }
      }
    }

    // When
    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      await assertions.assert(state: TestedState.idle, fail: spyFail)
      await assertions.assert(state: TestedState.loading, fail: spyFail)
    }

    // Then
    XCTAssertTrue(failIsCalled, "Expected XCTAssert to fail when timeout is triggered.")
  }

  func test_assertNoTransition_whenTimeoutIsTriggered_succeeds() async {
    // Given an async state machine
    let sut = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self, guard: { _, event in event.id != 1701 }) { _, _ in
          Transition(state: TestedState.loaded)
        }
      }
    }

    // When
    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      await assertions.assert(state: TestedState.idle, fail: spyFail)

      assertions.send(event: TestedEvent.loadingRequestedWithValue1701)

      await assertions.assertNoTransition(fail: spyFail)
    }

    // Then
    XCTAssertFalse(failIsCalled, "Expected XCTAssert to succeed but `spyFail` was called.")
  }

  func test_assertNoTransition_whenStateIsEmittewd_fails() async {
    // Given an async state machine
    let sut = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: TestedState.loaded)
        }
      }
    }

    // When
    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      await assertions.assert(state: TestedState.idle, fail: spyFail)

      assertions.send(event: TestedEvent.loadingRequestedWithValue1701)

      await assertions.assertNoTransition(fail: spyFail)
    }

    // Then
    XCTAssertTrue(failIsCalled, "Expected XCTAssert to fail but because the \(TestedState.loaded) state was emitted.")
  }
}

// MARK: Tests for XCTAssertNoTransition(asyncStateMachine:when:on:)

extension XCTAssertTests {
  func test_noTransitionAssertion_whenNoTransition_doesNotFail() async {
    // Given an async state machine

    // When
    await XCTAssertNoTransition(
      asyncStateMachine: AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle) {
        When(state: Idle.self) {
          On(event: ReloadingWasRequested.self) { _, _ in
            Transition(state: TestedState.loading)
          }
        }
      },
      when: TestedState.idle,
      on: TestedEvent.loadingRequestedWithValue1701,
      fail: spyFail
    )

    XCTAssertFalse(failIsCalled, "Expected XCTAssertNoTransition to succeed when no transition in the state machine.")
  }

  func test_noTransitionAssertion_whenTransition_fails() async {
    // Given an async state machine

    // When
    await XCTAssertNoTransition(
      asyncStateMachine: AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle) {
        When(state: Idle.self) {
          On(event: ReloadingWasRequested.self) { _, _ in
            Transition(state: TestedState.loading)
          }
        }
      },
      when: TestedState.idle,
      on: TestedEvent.reloadingRequestedWithValue1702,
      fail: spyFail
    )

    XCTAssertTrue(failIsCalled, "Expected XCTAssertNoTransition to fail when a transition exists in the state machine.")
  }
}

// MARK: Tests for XCTAssertTransition(asyncStateMachine:when:on:transitionsTo:)

extension XCTAssertTests {
  func test_transitionAssertion_whenTransition_doesNotFail() async {
    // Given an async state machine

    // When
    await XCTAssertTransition(
      asyncStateMachine: AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle) {
        When(state: Idle.self) {
          On(event: ReloadingWasRequested.self) { _, _ in
            Transition(state: TestedState.loading)
          }
        }
      },
      when: TestedState.idle,
      on: TestedEvent.reloadingRequestedWithValue1701,
      transitionsTo: TestedState.loading,
      fail: spyFail
    )

    XCTAssertFalse(
      failIsCalled,
      """
      Expected XCTAssertTransition to succeed when a transition to the expected state occurs.
      """
    )
  }

  func test_transitionAssertion_whenNoTransition_fails() async {
    // Given an async state machine

    // When
    await XCTAssertTransition(
      asyncStateMachine: AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle) {
        When(state: Idle.self) {
          On(event: ReloadingWasRequested.self) { _, _ in
            Transition(state: TestedState.loading)
          }
        }
      },
      when: TestedState.idle,
      on: TestedEvent.loadingSucceededWithValue1701,
      transitionsTo: TestedState.loading,
      fail: spyFail
    )

    XCTAssertTrue(
      failIsCalled,
      """
      Expected XCTAssertTransition to fail when no transition to expected state occurs.
      """
    )
  }
}
