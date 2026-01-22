import Combine
import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
final class UIStateMachineTests: XCTestCase {

  // MARK: - Lifecycle

  @MainActor
  override func tearDown() {
    super.tearDown()

    sutFromSuperState = nil
    sutFromUIState = nil
  }

  // MARK: - Properties

  var sutFromSuperState: UIStateMachine<MockSuperState, MockSuperEvent>!
  var sutFromUIState: UIStateMachine<MockUIState, MockSuperEvent>!

  // MARK: - Methods

  @MainActor
  func test_publish_whenSuperState_firstPublishedStateIsLastKnownState() {
    let initialState = TestedState.idle
    let expectedLastKnownState = TestedState.loading

    let stateMachine = AsyncStateMachine(initial: initialState) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: expectedLastKnownState)
        }
      }
    }

    // Given
    stateMachine.currentState.set(value: expectedLastKnownState)

    // When
    sutFromSuperState = UIStateMachine(asyncStateMachine: stateMachine)

    // Then
    let receivedState = sutFromSuperState.state

    XCTAssertEqual(
      receivedState,
      expectedLastKnownState.superState,
      """
      Expected the first published state to be the last known state \(expectedLastKnownState.superState),
      but got \(receivedState) instead
      """
    )
  }

  @MainActor
  func test_publish_whenSuperState_deliversDistinctStates() {
    let uiStateMachineHasPublishedTwoStates = expectation(
      description: "The ui state machine has published 2 states"
    )

    let uiStateMachineTaskIsFinished = expectation(
      description: "The iteration of the ui state machine is finished"
    )

    let initialState = TestedState.idle
    let finalState = TestedState.loaded
    let expected = [initialState.superState, finalState.superState]

    // Given
    sutFromSuperState =
      UIStateMachine(asyncStateMachine: AsyncStateMachine(initial: initialState) {
        When(state: Idle.self) {
          On(event: LoadingWasRequested.self) { _, _ in
            Transition(state: TestedState.loading)
          }
        }

        When(state: Loading.self) {
          On(event: ReloadingWasRequested.self) { _, _ in
            Transition(state: TestedState.loading)
          }

          On(event: LoadingHasSucceeded.self) { _, _ in
            Transition(state: finalState)
          }
        }
      })

    sutFromSuperState.onStop = { @Sendable in
      uiStateMachineTaskIsFinished.fulfill()
    }

    sutFromSuperState.start()

    let cancellable: AnyCancellable
    var received = [MockSuperState]()
    cancellable = sutFromSuperState.$state.sink { superState in
      received.append(superState)
      if received.count == 2 {
        uiStateMachineHasPublishedTwoStates.fulfill()
      }
    }

    // When
    Task {
      sutFromSuperState.send(TestedEvent.loadingRequestedWithValue1701)
      await sutFromSuperState.sendAndWait(TestedEvent.reloadingRequestedWithValue1702)
      sutFromSuperState.send(TestedEvent.loadingSucceededWithValue1703)
    }

    // Then
    wait(for: [uiStateMachineHasPublishedTwoStates], timeout: 1.0)
    XCTAssertEqual(received, expected)

    sutFromSuperState.uiStateSequenceTask?.cancel()
    cancellable.cancel()

    wait(for: [uiStateMachineTaskIsFinished], timeout: 1.0)
  }

  @MainActor
  func test_publish_whenUIState_firstPublishedStateIsLastKnownState() {
    let initialState = TestedState.idle
    let expectedLastKnownState = TestedState.loading

    @Sendable
    func superStateToUIState(superState: MockSuperState) -> MockUIState {
      MockUIState(isLoading: !superState.isLoaded)
    }

    let stateMachine = AsyncStateMachine(initial: initialState) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: expectedLastKnownState)
        }
      }
    }

    // Given
    stateMachine.currentState.set(value: expectedLastKnownState)

    // When
    sutFromUIState = UIStateMachine(asyncStateMachine: stateMachine, mapping: superStateToUIState)

    // Then
    let receivedState = sutFromUIState.state
    let expectedState = superStateToUIState(superState: expectedLastKnownState.superState)

    XCTAssertEqual(
      receivedState,
      expectedState,
      """
      Expected the first published UI state to be the last known state \(expectedState),
      but got \(receivedState) instead
      """
    )
  }

  @MainActor
  func test_publish_whenUIState_deliversDistinctStates() {
    let uiStateMachineHasPublishedTwoStates = expectation(
      description: "The ui state machine has published 2 states"
    )
    let uiStateMachineTaskIsFinished = expectation(
      description: "The iteration of the ui state machine is finished"
    )

    @Sendable
    func superStateToUIState(superState: MockSuperState) -> MockUIState {
      MockUIState(isLoading: !superState.isLoaded)
    }

    let initialState = TestedState.idle
    let finalState = TestedState.loaded
    let expected = [
      superStateToUIState(superState: initialState.superState),
      superStateToUIState(superState: finalState.superState),
    ]

    // Given
    sutFromUIState =
      UIStateMachine(asyncStateMachine: AsyncStateMachine(initial: initialState) {
        When(state: Idle.self) {
          On(event: LoadingWasRequested.self) { _, _ in
            Transition(state: TestedState.loading)
          }
        }

        When(state: Loading.self) {
          On(event: ReloadingWasRequested.self) { _, _ in
            Transition(state: TestedState.loading)
          }

          On(event: LoadingHasSucceeded.self) { _, _ in
            Transition(state: finalState)
          }
        }
      }, mapping: superStateToUIState)

    sutFromUIState.onStop = { @Sendable in
      uiStateMachineTaskIsFinished.fulfill()
    }
    sutFromUIState.start()

    let cancellable: AnyCancellable
    var received = [MockUIState]()
    cancellable = sutFromUIState.$state.sink { viewState in
      received.append(viewState)
      if received.count == 2 {
        uiStateMachineHasPublishedTwoStates.fulfill()
      }
    }

    // When
    Task {
      await sutFromUIState.sendAndWait(TestedEvent.loadingRequestedWithValue1701)
      sutFromUIState.send(TestedEvent.reloadingRequestedWithValue1702)
      await sutFromUIState.sendAndWait(TestedEvent.loadingSucceededWithValue1703)
    }

    // Then
    wait(for: [uiStateMachineHasPublishedTwoStates], timeout: 1.0)
    XCTAssertEqual(received, expected)

    sutFromUIState.uiStateSequenceTask?.cancel()
    cancellable.cancel()

    wait(for: [uiStateMachineTaskIsFinished], timeout: 1.0)
  }

  @MainActor
  func test_start_whenStateMachineAlreadyStarted_doesNotStartNewTask() {
    let uiStateMachineIsStarted = expectation(description: "The ui state machine is started")
    let uiStateMachineTaskIsFinished = expectation(
      description: "The iteration of the ui state machine is finished"
    )

    // Given
    sutFromSuperState =
      UIStateMachine(asyncStateMachine: AsyncStateMachine(initial: TestedState.idle) {
        When(state: Idle.self) {
          On(event: LoadingWasRequested.self) { _, _ in
            Transition(state: TestedState.loading)
          }
        }
      })

    sutFromSuperState.onStart = { @Sendable in
      uiStateMachineIsStarted.fulfill()
    }

    sutFromSuperState.onStop = { @Sendable in
      uiStateMachineTaskIsFinished.fulfill()
    }

    sutFromSuperState.start()
    let originalTask = sutFromSuperState.uiStateSequenceTask

    wait(for: [uiStateMachineIsStarted], timeout: 1.0)

    // When
    sutFromSuperState.start()
    let currentTask = sutFromSuperState.uiStateSequenceTask

    // Then
    XCTAssertEqual(originalTask, currentTask)

    sutFromSuperState.uiStateSequenceTask?.cancel()

    wait(for: [uiStateMachineTaskIsFinished], timeout: 1.0)
  }

  @MainActor
  func test_start_whenTaskCancelledAndStartCalledAgain_continuesAsyncStateMachine() {
    let uiStateMachineHasEmittedTwoStatesForTask1 = expectation(
      description: "The ui state machine has emitted 2 states (first task)"
    )
    uiStateMachineHasEmittedTwoStatesForTask1.expectedFulfillmentCount = 2

    let uiStateMachineHasEmittedOneStateForTask2 = expectation(
      description: "The ui state machine has emitted 1 state (second task)"
    )

    let startCalledTwice = expectation(description: "The start function was called twice.")
    startCalledTwice.expectedFulfillmentCount = 2

    // Given
    sutFromSuperState =
      UIStateMachine(asyncStateMachine: AsyncStateMachine(initial: TestedState.loading) {
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
      })

    // add expectation fulfilled when onStart called twice, and wait for it before stopping the test
    sutFromSuperState.onStart = { @Sendable in
      startCalledTwice.fulfill()
    }

    let cancellable1 = sutFromSuperState.$state.sink { _ in
      uiStateMachineHasEmittedTwoStatesForTask1.fulfill()
    }

    // When
    sutFromSuperState.start()

    sutFromSuperState.send(TestedEvent.loadingSucceededWithValue1701)

    wait(for: [uiStateMachineHasEmittedTwoStatesForTask1], timeout: 1.0)

    cancellable1.cancel()
    sutFromSuperState.uiStateSequenceTask?.cancel()
    sutFromSuperState.uiStateSequenceTask = nil

    // Then
    sutFromSuperState.start()

    wait(for: [startCalledTwice], timeout: 1.0)

    let cancellable2 = sutFromSuperState.$state.sink { _ in
      uiStateMachineHasEmittedOneStateForTask2.fulfill()
    }

    sutFromSuperState.send(TestedEvent.reloadingRequestedWithValue1701)

    wait(for: [uiStateMachineHasEmittedOneStateForTask2], timeout: 1.0)

    cancellable2.cancel()
  }

  @MainActor
  func test_deinit_whenCalled_cancelsTheAsyncSequenceTask() {
    let uiStateMachineIsStarted = expectation(
      description: "The ui state machine is started"
    )

    let uiStateMachineTaskIsFinished = expectation(
      description: "The iteration of the ui state machine is finished"
    )

    // Given
    var sut: UIStateMachine<MockSuperState, MockSuperEvent>? =
      UIStateMachine(asyncStateMachine: AsyncStateMachine(initial: TestedState.idle) {
        When(state: Idle.self) {
          On(event: LoadingWasRequested.self) { _, _ in
            Transition(state: TestedState.loading)
          }
        }
      })

    sut?.onStart = { @Sendable in
      uiStateMachineIsStarted.fulfill()
    }

    let task = sut?.uiStateSequenceTask
    Task {
      let _ = await task?.value
      uiStateMachineTaskIsFinished.fulfill()
    }

    sut?.start()

    wait(for: [uiStateMachineIsStarted], timeout: 1.0)

    // When
    sut = nil

    // Then
    wait(for: [uiStateMachineTaskIsFinished], timeout: 1.0)
  }
}
