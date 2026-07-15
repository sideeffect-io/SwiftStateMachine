import StateMachineShared
import StateMachineTest
import XCTest
@testable import StateMachineCore

// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
// swiftlint:disable file_length
// swiftlint:disable implicitly_unwrapped_optional

final class AsyncStateMachineTests: XCTestCase, @unchecked Sendable {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: AsyncStateMachine<MockSuperState, MockSuperEvent>!

  // MARK: - Methods

  func test_init_withInitialState_publishesExpectedStateSequence() async {
    let expectedInitialState = TestedState.idle
    let expectedLoadingState = TestedState.loading
    let expectedLoadedState = TestedState.loaded
    let expectedNumberOfStatesCollected = 3

    // Given
    sut = AsyncStateMachine(initial: expectedInitialState) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: expectedLoadingState)
        }
      }

      When(state: Loading.self) {
        On(event: LoadingHasSucceeded.self) { _, _ in
          Transition(state: expectedLoadedState)
        }
      }

    }

    // When
    sut.send(event: TestedEvent.loadingRequestedWithValue1701)
    sut.send(event: TestedEvent.loadingSucceededWithValue1701)
    sut.finish()

    // Then
    XCTAssertEqual(
      sut.lastKnownState as? Idle,
      expectedInitialState,
      """
      Expected the last known state to be \(expectedInitialState) before iteration begins,
      but got \(sut.lastKnownState) instead
      """
    )

    // When
    var collected = [any State<MockSuperState>]()
    for await state in sut {
      collected.append(state)
    }

    // Then
    XCTAssertEqual(
      sut.lastKnownState as? Loaded,
      expectedLoadedState,
      """
      Expected last known state to be \(expectedLoadedState) after iteration ended,
      but got \(sut.lastKnownState)
      """
    )

    let numberOfStatesCollected = collected.count
    XCTAssertEqual(
      numberOfStatesCollected,
      expectedNumberOfStatesCollected,
      """
      Expected to collect a sequence of \(expectedNumberOfStatesCollected) states.
      Collected a sequence of \(numberOfStatesCollected) states instead.
      """
    )

    let firstStateCollected = collected[0] as? Idle
    XCTAssertEqual(
      firstStateCollected,
      expectedInitialState,
      """
      Expected first state collected to be \(expectedInitialState),
      but got \(String(describing: firstStateCollected)) instead.
      """
    )

    let secondStateCollected = collected[1] as? Loading
    XCTAssertEqual(
      secondStateCollected,
      expectedLoadingState,
      """
      Expected second state collected to be \(expectedLoadingState),
      but got \(String(describing: secondStateCollected))
      """
    )

    let thirdStateCollected = collected[2] as? Loaded
    XCTAssertEqual(
      thirdStateCollected,
      expectedLoadedState,
      """
      Expected third state collected to be \(expectedLoadedState),
      but got \(String(describing: thirdStateCollected))
      """
    )
  }

  func test_init_withStateMachineWithOutput_publishesExpectedStateSequence() async {
    let expectedInitialState = TestedState.idle
    let expectedLoadingState = TestedState.loading
    let expectedLoadedState = TestedState.loaded

    // Given
    let stateMachine = StateMachine<MockSuperState, MockSuperEvent>(initial: expectedInitialState) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: expectedLoadingState)
          Output {
            TestedEvent.loadingSucceededWithValue1701
          }
        }
      }

      When(state: Loading.self) {
        On(event: LoadingHasSucceeded.self) { _, _ in
          Transition(state: expectedLoadedState)
        }
      }
    }

    // When
    sut = AsyncStateMachine(stateMachine: stateMachine)
    sut.send(event: TestedEvent.loadingRequestedWithValue1701)

    // Then
    var iterator = sut.makeAsyncIterator()

    let state1 = await iterator.next()
    let state1Collected = state1 as? Idle
    XCTAssertEqual(
      state1Collected,
      expectedInitialState,
      "Expected state1 to be \(expectedInitialState), but got \(String(describing: state1Collected)) instead."
    )

    let state2 = await iterator.next()
    let state2Collected = state2 as? Loading
    XCTAssertEqual(
      state2Collected,
      expectedLoadingState,
      "Expected state2 to be \(expectedLoadingState), but got \(String(describing: state2Collected)) instead."
    )

    let state3 = await iterator.next()
    let state3Collected = state3 as? Loaded
    XCTAssertEqual(
      state3Collected,
      expectedLoadedState,
      "Expected state3 to be \(expectedLoadedState), but got \(String(describing: state3Collected)) instead."
    )

    sut.finish()
  }

  func test_init_withStateMachineWithCancellableOutput_publishesExpectedStateSequenceAndCancelsOutputOnRequest(
  ) {
    let sideEffectIsRunning = expectation(description: "The side effect is currently running")
    let sideEffectWasCancelled = expectation(description: "The side effect was cancelled")
    let taskIsFinished = expectation(description: "The root task has finished")

    let expectedInitialState = TestedState.idle
    let expectedLoadingState = TestedState.loading
    let expectedFinalState = TestedState.failed

    // Given
    let stateMachine = StateMachine<MockSuperState, MockSuperEvent>(initial: expectedInitialState) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: expectedLoadingState)
          Output {
            await suspendedSideEffect(
              onSuspended: { sideEffectIsRunning.fulfill() },
              onCancel: { sideEffectWasCancelled.fulfill() },
              resumeWith: { nil }
            )
          }.cancellationPolicy(cancel: Cancel(whencurrentState: Loading.self, on: ReloadingWasRequested.self))
        }
      }

      When(state: Loading.self) {
        On(event: ReloadingWasRequested.self) { _, _ in
          Transition(state: expectedFinalState)
        }
      }
    }

    // When
    sut = AsyncStateMachine(stateMachine: stateMachine)
    sut.send(event: TestedEvent.loadingRequestedWithValue1701)

    // Then
    Task {
      var iterator = sut.makeAsyncIterator()

      let state1 = await iterator.next()
      let state1Collected = state1 as? Idle
      XCTAssertEqual(
        state1Collected,
        expectedInitialState,
        "Expected state1 to be \(expectedInitialState), but got \(String(describing: state1Collected)) instead."
      )

      let state2 = await iterator.next()
      let state2Collected = state2 as? Loading
      XCTAssertEqual(
        state2Collected,
        expectedLoadingState,
        "Expected state2 to be \(expectedLoadingState), but got \(String(describing: state2Collected)) instead."
      )

      let state3 = await iterator.next()
      let state3Collected = state3 as? Failed
      XCTAssertEqual(
        state3Collected,
        expectedFinalState,
        "Expected state3 to be \(expectedFinalState), but got \(String(describing: state3Collected)) instead."
      )

      taskIsFinished.fulfill()
    }

    wait(for: [sideEffectIsRunning], timeout: 1.0)

    // When
    sut.send(event: TestedEvent.reloadingRequestedWithValue1702)

    // Then
    wait(for: [sideEffectWasCancelled], timeout: 1.0)
    wait(for: [taskIsFinished], timeout: 1.0)
    sut.finish()
  }

  func test_integration_lifecyclePolicyAndCancellationPolicy_withDsl() async {
    let loadAttempts = SendableStorage(value: 0)
    let pollRuns = SendableStorage(value: 0)

    let load = IntegrationLoad { id in
      let attempt = loadAttempts.apply { current in
        current += 1
        return current
      }
      if attempt < 3 {
        throw IntegrationError(attempt: attempt)
      }
      return "value-\(id)"
    }

    let poll = IntegrationPoll {
      pollRuns.apply { $0 += 1 }
      return "tick"
    }

    let clock = IntegrationClock { _ in }

    let stateMachine = StateMachine<IntegrationSuperState, IntegrationEvent>(initial: IntegrationIdle()) {
      When(states: IntegrationIdle.self, IntegrationFailed.self) {
        On(event: IntegrationDidRequestLoad.self) { _, event in
          Transition(state: IntegrationLoading(id: event.id))
          Output(sideEffect: load(eventId: event.id))
            .cancellationPolicy(cancel: Cancel(on: IntegrationDidRequestLoad.self))
            .lifecyclePolicy(.restartOnFailure(maxRestarts: 2, delay: { attempt in
              await clock.sleep(.milliseconds(1 * attempt))
            }))
            .onFailure { error in
              let attempt = (error as? IntegrationError)?.attempt ?? -1
              return IntegrationDidFail(message: "attempt-\(attempt)")
            }
        }
      }

      When(state: IntegrationLoading.self) {
        On(event: IntegrationDidFail.self) { _, event in
          Transition(state: IntegrationFailed(message: event.message))
        }

        On(event: IntegrationDidSucceed.self) { _, event in
          Transition(state: IntegrationLoaded(value: event.value, count: 0))
          Output(sideEffect: poll())
            .lifecyclePolicy(.restartOnCompletion(maxRestarts: 2))
        }
      }

      When(state: IntegrationFailed.self) {
        On(event: IntegrationDidFail.self) { _, event in
          Transition(state: IntegrationFailed(message: event.message))
        }

        On(event: IntegrationDidSucceed.self) { _, event in
          Transition(state: IntegrationLoaded(value: event.value, count: 0))
          Output(sideEffect: poll())
            .lifecyclePolicy(.restartOnCompletion(maxRestarts: 2))
        }
      }

      When(state: IntegrationLoaded.self) {
        On(event: IntegrationTick.self) { state, _ in
          Transition(state: IntegrationLoaded(value: state.value, count: state.count + 1))
        }
      }
    }

    let asyncStateMachine = AsyncStateMachine<IntegrationSuperState, IntegrationEvent>(
      stateMachine: stateMachine
    )

    await XCTAssert(asyncStateMachine: asyncStateMachine, timeout: .seconds(1)) { assertions in
      await assertions.assert(state: IntegrationIdle())

      assertions.send(event: IntegrationDidRequestLoad(id: "42"))

      await assertions.assert(state: IntegrationLoading(id: "42"))
      await assertions.assert(state: IntegrationFailed(message: "attempt-1"))
      await assertions.assert(state: IntegrationFailed(message: "attempt-2"))
      await assertions.assert(state: IntegrationLoaded(value: "value-42", count: 0))
      await assertions.assert(state: IntegrationLoaded(value: "value-42", count: 1))
      await assertions.assert(state: IntegrationLoaded(value: "value-42", count: 2))
      await assertions.assert(state: IntegrationLoaded(value: "value-42", count: 3))

      await assertions.assertNoTransition(timeout: .milliseconds(100))
    }

    loadAttempts.assertEqual(expected: 3)
    pollRuns.assertEqual(expected: 3)
  }

  func test_sendAndWait_whenOutputIsDone_suspendsAndResumes() {
    let sideEffectIsSuspended = expectation(description: "The side effect is running and suspended")
    let sideEffectIsResumed = expectation(description: "The side effect is resumed")

    let eventIsResumed = SendableStorage(value: false)

    let (sideEffect, continuation) = makeResumableSideEffect(
      onSuspended: { sideEffectIsSuspended.fulfill() },
      resumeWith: TestedEvent.loadingSucceededWithValue1701
    )

    // Given
    sut = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: Loading())
          Output(sideEffect: sideEffect)
        }
      }
    }

    let task = Task {
      for await _ in sut { }
    }

    // when
    Task {
      await sut.sendAndWait(event: LoadingWasRequested(id: 1701))
      eventIsResumed.set(value: true)
      sideEffectIsResumed.fulfill()
    }

    // Then
    wait(for: [sideEffectIsSuspended], timeout: 1.0)

    XCTAssertFalse(eventIsResumed.get(), "Event is suspended. Expected resumed to be false, but got true instead.")

    continuation.apply { continuation in
      continuation?.resume()
    }

    wait(for: [sideEffectIsResumed], timeout: 1.0)

    XCTAssertTrue(eventIsResumed.get(), "Event is resumed. Expected resumed to be true, but got false instead.")
    task.cancel()
  }

  func test_sendAndWait_whenNoOutput_resumesImmediately() async {
    // Given
    sut = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: Loading())
        }
      }
    }

    let task = Task {
      for await _ in sut { }
    }

    // when
    let sendingTask = Task {
      await sut.sendAndWait(event: TestedEvent.loadingRequestedWithValue1701)
    }

    // Then
    await sendingTask.value
    task.cancel()
  }

  func test_cancellingSendAndWait_endsOnlyTheCallersWait() async {
    let outputStarted = expectation(description: "The output started")
    let outputCancelled = expectation(description: "The output was cancelled during terminal shutdown")
    let callerReturned = expectation(description: "The cancelled caller returned without waiting for the output")

    sut = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: Loading())
          Output {
            await suspendedSideEffect(
              onSuspended: { outputStarted.fulfill() },
              onCancel: { outputCancelled.fulfill() },
              resumeWith: { nil }
            )
          }
        }
      }
    }

    let sendTask = Task {
      await self.sut.sendAndWait(event: LoadingWasRequested(id: 1701))
      callerReturned.fulfill()
    }

    await fulfillment(of: [outputStarted], timeout: 1.0)
    sendTask.cancel()
    await fulfillment(of: [callerReturned], timeout: 1.0)

    XCTAssertTrue(sut.lastKnownState is Loading)
    await sut.finishAndWait()
    await fulfillment(of: [outputCancelled], timeout: 1.0)
  }

  func test_sendBeforeObservation_processesCommandsAndBuffersStates() async {
    sut = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: Loading())
        }
      }
    }

    await sut.sendAndWait(
      event: LoadingWasRequested(id: 1701),
      until: .transitionCommitted
    )

    XCTAssertTrue(sut.lastKnownState is Loading)

    var iterator = sut.makeAsyncIterator()
    let initial = await iterator.next()
    let loading = await iterator.next()
    XCTAssertTrue(initial is Idle)
    XCTAssertTrue(loading is Loading)
    await sut.finishAndWait()
    let finished = await iterator.next()
    XCTAssertNil(finished)
  }

  func test_send_eventWithAssociatedTransition_executesTransition() async {
    typealias OnTransitionValues = (
      currentState: any State<MockSuperState>,
      event: any Event<MockSuperEvent>,
      newState: any State<MockSuperState>
    )
    let middlewareHaveBeenExecuted = expectation(description: "The registered middleware have been executed")
    middlewareHaveBeenExecuted.expectedFulfillmentCount = 2

    let expectedInitialState = TestedState.idle
    let expectedLoadingWasRequestedEvent = TestedEvent.loadingRequestedWithValue1701
    let expectedLoadingState = TestedState.loading
    let expectedLoadingHasSucceededEvent = TestedEvent.loadingSucceededWithValue1701
    let expectedLoadedState = TestedState.loaded

    let receivedIdInTransition = SendableStorage<UUID?>(value: nil)

    let spy = SendableStorage<[ObjectIdentifier: OnTransitionValues]>(value: [:])

    // Given
    let stateMachine = StateMachine<MockSuperState, MockSuperEvent>(initial: expectedInitialState) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: expectedLoadingState)
        }
      }

      When(state: Loading.self) {
        On(event: LoadingHasSucceeded.self) { _, _ in
          Transition(state: expectedLoadedState)
        }
      }
    }

    sut = AsyncStateMachine(stateMachine: stateMachine)
      .onTransition { stateMachineId, currentState, event, newState in
        receivedIdInTransition.set(value: stateMachineId)

        spy.apply { values in
          values[ObjectIdentifier(type(of: currentState))] = OnTransitionValues(currentState, event, newState)
          middlewareHaveBeenExecuted.fulfill()
        }
      }

    // When
    var iterator = sut.makeAsyncIterator()
    _ = await iterator.next()

    sut.send(event: expectedLoadingWasRequestedEvent)
    _ = await iterator.next()

    sut.send(event: expectedLoadingHasSucceededEvent)
    _ = await iterator.next()

    await fulfillment(of: [middlewareHaveBeenExecuted], timeout: 1.0)

    // Then
    let collected = spy.get()
    let idleStateObjectIdentifier = ObjectIdentifier(Idle.self)
    let loadingStateObjectIdentifier = ObjectIdentifier(Loading.self)

    let firstStateCollected = collected[idleStateObjectIdentifier]?.currentState as? Idle
    XCTAssertEqual(
      firstStateCollected,
      expectedInitialState,
      """
      Expected first state collected to be \(expectedInitialState),
      but got \(String(describing: firstStateCollected)) instead.
      """
    )

    let firstEventCollected = collected[idleStateObjectIdentifier]?.event as? LoadingWasRequested
    XCTAssertEqual(
      firstEventCollected,
      expectedLoadingWasRequestedEvent,
      """
      Expected first event collected to be \(expectedLoadingWasRequestedEvent),
      but got \(String(describing: firstEventCollected)) instead.
      """
    )

    let firstNewStateCollected = collected[idleStateObjectIdentifier]?.newState as? Loading
    XCTAssertEqual(
      firstNewStateCollected,
      expectedLoadingState,
      """
      Expected first new state collected to be \(expectedLoadingState),
      but got \(String(describing: firstNewStateCollected)) instead.
      """
    )

    let secondStateCollected = collected[loadingStateObjectIdentifier]?.currentState as? Loading
    XCTAssertEqual(
      secondStateCollected,
      expectedLoadingState,
      """
      Expected second state collected to be \(expectedLoadingState),
      but got \(String(describing: secondStateCollected)) instead.
      """
    )

    let secondEventCollected = collected[loadingStateObjectIdentifier]?.event as? LoadingHasSucceeded
    XCTAssertEqual(
      secondEventCollected,
      expectedLoadingHasSucceededEvent,
      """
      Expected second event collected to be \(expectedLoadingHasSucceededEvent),
      but got \(String(describing: secondEventCollected)) instead.
      """
    )

    let secondNewStateCollected = collected[loadingStateObjectIdentifier]?.newState as? Loaded
    XCTAssertEqual(
      secondNewStateCollected,
      expectedLoadedState,
      """
      Expected second new state collected to be \(expectedLoadedState),
      but got \(String(describing: secondNewStateCollected)) instead.
      """
    )

    XCTAssertEqual(
      receivedIdInTransition.get(),
      sut.id,
      """
      Expected state machine id to be \(sut.id),
      but got \(receivedIdInTransition.get()!) instead
      """
    )
  }

  func test_cancellingStateObservation_doesNotCancelRunningOutput() async {
    let sideEffectIsRunning = expectation(description: "The side effect is currently running")
    let sideEffectWasCancelled = expectation(description: "The side effect was cancelled")
    let firstTaskIsFinished = expectation(description: "The first task has finished")

    let expectedInitialState = TestedState.idle
    let expectedLoadingState = TestedState.loading
    let expectedLoadedState = TestedState.loaded

    // Given
    let stateMachine = StateMachine<MockSuperState, MockSuperEvent>(initial: expectedInitialState) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: expectedLoadingState)
          Output {
            await suspendedSideEffect(
              onSuspended: { sideEffectIsRunning.fulfill() },
              onCancel: { sideEffectWasCancelled.fulfill() },
              resumeWith: { nil }
            )
          }
        }
      }

      When(state: Loading.self) {
        On(event: LoadingHasSucceeded.self) { _, _ in
          Transition(state: expectedLoadedState)
        }
      }
    }

    sut = AsyncStateMachine(stateMachine: stateMachine)

    let task = Task {
      var collected = [any State<MockSuperState>]()
      var iterator = sut.makeAsyncIterator()

      while let state = await iterator.next() {
        collected.append(state)
      }

      let firstStateCollected = collected[0] as? Idle
      XCTAssertEqual(
        firstStateCollected,
        expectedInitialState,
        """
        Expected first state collected to be \(expectedInitialState),
        but got \(String(describing: firstStateCollected)) instead.
        """
      )

      let secondStateCollected = collected[1] as? Loading
      XCTAssertEqual(
        secondStateCollected,
        expectedLoadingState,
        """
        Expected second state collected to be \(expectedLoadingState),
        but got \(String(describing: secondStateCollected)) instead.
        """
      )

      let pastEnd = await iterator.next()
      XCTAssertNil(
        pastEnd,
        """
        Expected a `nil` value when calling `next()` on the iterator as the sequence was finished,
        but got \(String(describing: pastEnd)) instead.
        """
      )

      firstTaskIsFinished.fulfill()
    }

    sut.send(event: TestedEvent.loadingRequestedWithValue1701)

    await fulfillment(of: [sideEffectIsRunning], timeout: 1.0)

    // When
    task.cancel()

    // Observation cancellation is intentionally independent from the command
    // runtime. The output remains supervised until a state-machine cancellation
    // policy or terminal finish requests its cancellation.
    await fulfillment(of: [firstTaskIsFinished], timeout: 1.0)
    let runningTaskCount = await sut.runtime.tasksInProgress.count
    XCTAssertEqual(runningTaskCount, 1)

    sut.finish()
    await fulfillment(of: [sideEffectWasCancelled], timeout: 1.0)

  }

  func test_finish_endsStreamAndCancelsTasks() {
    let sideEffectIsRunning = expectation(description: "The side effect is currently running")
    let sideEffectWasCancelled = expectation(description: "The side effect was cancelled")
    let taskIsFinished = expectation(description: "The root task has finished")

    let expectedInitialState = TestedState.idle
    let expectedLoadingState = TestedState.loading

    // Given
    let stateMachine = StateMachine<MockSuperState, MockSuperEvent>(initial: expectedInitialState) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: expectedLoadingState)
          Output {
            await suspendedSideEffect(
              onSuspended: { sideEffectIsRunning.fulfill() },
              onCancel: { sideEffectWasCancelled.fulfill() },
              resumeWith: { nil }
            )
          }
        }
      }
    }

    sut = AsyncStateMachine(stateMachine: stateMachine)

    Task {
      var collected = [any State<MockSuperState>]()
      var iterator = sut.makeAsyncIterator()

      while let state = await iterator.next() {
        collected.append(state)
      }

      let firstStateCollected = collected[0] as? Idle
      XCTAssertEqual(
        firstStateCollected,
        expectedInitialState,
        """
        Expected first state collected to be \(expectedInitialState),
        but got \(String(describing: firstStateCollected)) instead.
        """
      )

      let secondStateCollected = collected[1] as? Loading
      XCTAssertEqual(
        secondStateCollected,
        expectedLoadingState,
        """
        Expected second state collected to be \(expectedLoadingState),
        but got \(String(describing: secondStateCollected)) instead.
        """
      )

      let pastEnd = await iterator.next()
      XCTAssertNil(
        pastEnd,
        """
        Expected a `nil` value when calling `next()` on the iterator as the sequence was finished,
        but got \(String(describing: pastEnd)) instead.
        """
      )

      taskIsFinished.fulfill()
    }

    sut.send(event: TestedEvent.loadingRequestedWithValue1701)

    wait(
      for: [
        sideEffectIsRunning,
      ],
      timeout: 1.0
    )

    // When
    sut.finish()

    // Then
    wait(
      for: [
        sideEffectWasCancelled,
      ],
      timeout: 1.0
    )
    wait(
      for: [
        taskIsFinished,
      ],
      timeout: 1.0
    )
  }

  func test_finishAndWait_waitsForAnUncooperativeOutputToActuallyExit() async {
    let outputStarted = expectation(description: "The output started")
    let cancellationRequested = expectation(description: "The output received a cancellation request")
    let continuation = SendableStorage<UnsafeContinuation<Void, Never>?>(value: nil)
    let didFinish = SendableStorage(value: false)

    let sideEffect: @Sendable () async -> (any Event<MockSuperEvent>)? = {
      await withTaskCancellationHandler(operation: {
        await withUnsafeContinuation { (continuationToResume: UnsafeContinuation<Void, Never>) in
          continuation.set(value: continuationToResume)
          outputStarted.fulfill()
        }
      }, onCancel: {
        // Deliberately do not resume: this models a side effect that only
        // exits after an external resource acknowledges shutdown.
        cancellationRequested.fulfill()
      })
      return nil
    }

    sut = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: Loading())
          Output(sideEffect: sideEffect)
        }
      }
    }

    sut.send(event: LoadingWasRequested(id: 1701))
    await fulfillment(of: [outputStarted], timeout: 1.0)

    let finishTask = Task {
      await self.sut.finishAndWait()
      didFinish.set(value: true)
    }

    await fulfillment(of: [cancellationRequested], timeout: 1.0)
    XCTAssertFalse(didFinish.get())

    continuation.get()?.resume()
    await finishTask.value
    XCTAssertTrue(didFinish.get())
  }

  func test_onInitialStates_whenInitialStateIsEmitted_areCalledWithExpectedUUIDAndInitialState() {
    let onInitialStatesWereCalled = expectation(description: "on initial states were called")
    onInitialStatesWereCalled.expectedFulfillmentCount = 2

    let receivedUUID1 = SendableStorage<UUID?>(value: nil)
    let receivedState1 = SendableStorage<(any State<MockSuperState>)?>(value: nil)

    let receivedUUID2 = SendableStorage<UUID?>(value: nil)
    let receivedState2 = SendableStorage<(any State<MockSuperState>)?>(value: nil)

    let expectedState = TestedState.idle

    sut = AsyncStateMachine(initial: expectedState) { }
    let expectedUUID = sut.id

    // Given
    sut.onInitialState { uuid, state in
      receivedUUID1.set(value: uuid)
      receivedState1.set(value: state)
      onInitialStatesWereCalled.fulfill()
    }

    sut.onInitialState { uuid, state in
      receivedUUID2.set(value: uuid)
      receivedState2.set(value: state)
      onInitialStatesWereCalled.fulfill()
    }

    // When
    let task = Task {
      for await _ in sut { }
    }

    wait(for: [onInitialStatesWereCalled], timeout: 1.0)

    // Then
    let unwrappedReceivedUUID1 = receivedUUID1.get()!
    let unwrappedReceivedState1 = receivedState1.get()!

    let unwrappedReceivedUUID2 = receivedUUID2.get()!
    let unwrappedReceivedState2 = receivedState2.get()!

    XCTAssertEqual(
      unwrappedReceivedUUID1,
      expectedUUID,
      "Expected to receive UUID \(expectedUUID), but got \(unwrappedReceivedUUID1) instead"
    )

    XCTAssertEqual(
      anyLhs: unwrappedReceivedState1,
      anyRhs: expectedState
    )

    XCTAssertEqual(
      unwrappedReceivedUUID2,
      expectedUUID,
      "Expected to receive UUID \(expectedUUID), but got \(unwrappedReceivedUUID2) instead"
    )

    XCTAssertEqual(
      anyLhs: unwrappedReceivedState2,
      anyRhs: expectedState
    )

    task.cancel()
  }

  func test_onDeinits_whenReferenceIsReleased_areCalledWithExpectedUUID() async {
    let receivedUUID1 = SendableStorage<UUID?>(value: nil)
    let receivedUUID2 = SendableStorage<UUID?>(value: nil)
    let didDeinit = expectation(description: "The ordered deinit callbacks are delivered")
    didDeinit.expectedFulfillmentCount = 2

    sut = AsyncStateMachine(initial: Idle()) { }
    let expectedUUID = sut.id

    // Given
    sut.onDeinit { uuid in
      receivedUUID1.set(value: uuid)
      didDeinit.fulfill()
    }

    sut.onDeinit { uuid in
      receivedUUID2.set(value: uuid)
      didDeinit.fulfill()
    }

    // When
    sut = nil

    await fulfillment(of: [didDeinit], timeout: 1.0)

    // Then
    let unwrappedReceivedUUID1 = receivedUUID1.get()!
    let unwrappedReceivedUUID2 = receivedUUID2.get()!

    XCTAssertEqual(
      receivedUUID1.get(),
      expectedUUID,
      "Expected to receive UUID \(expectedUUID), but got \(unwrappedReceivedUUID1) instead"
    )

    XCTAssertEqual(
      receivedUUID2.get(),
      expectedUUID,
      "Expected to receive UUID \(expectedUUID), but got \(unwrappedReceivedUUID2) instead"
    )
  }

  func test_disableLog_whenTransitionHappens_nothingIsLogged() async {
    let isLogCalled = SendableStorage(value: false)

    // Given
    StateMachineCore.setLogger { _, _, _, _ in
      isLogCalled.set(value: true)
    }

    sut = AsyncStateMachine(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: Loading())
          Output(sideEffect: { nil })
        }
      }
    }
    sut.disableLog()

    let task = Task {
      for await _ in sut { }
    }

    // When
    await sut.sendAndWait(event: LoadingWasRequested(id: 1701))

    // Then
    XCTAssertFalse(
      isLogCalled.get(),
      "The log function should not be called, but was."
    )

    task.cancel()
  }

  func test_onLifecycleEvent_whenTransitionIsPerformed_areCalledWithExpectedEvent() async {
    let firstLifecycleEventWasReceived = expectation(description: "The first lifecycle event was received")
    let secondLifecycleEventWasReceived = expectation(description: "The second lifecycle event was received")

    let expectedInitialState = TestedState.idle
    let expectedLoadingWasRequestedEvent = TestedEvent.loadingRequestedWithValue1701
    let expectedLoadingState = TestedState.loading

    let spy = SendableStorage<[AsyncStateMachine<MockSuperState, MockSuperEvent>.LifecycleEvent]>(value: [])

    // Given
    let stateMachine = StateMachine<MockSuperState, MockSuperEvent>(initial: expectedInitialState) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: expectedLoadingState)
        }
      }
    }

    sut = AsyncStateMachine(stateMachine: stateMachine)
      .onLifecycleEvent { event in
        spy.apply { values in
          values.append(event)
          if values.count == 1 {
            firstLifecycleEventWasReceived.fulfill()
          }
          if values.count == 2 {
            secondLifecycleEventWasReceived.fulfill()
          }
        }
      }

    // When
    var iterator = sut.makeAsyncIterator()
    _ = await iterator.next()

    await fulfillment(of: [firstLifecycleEventWasReceived], timeout: 1.0)

    // Then
    let firstEventCollected = spy.get()[0]

    XCTAssertEqual(
      firstEventCollected.currentState as? Idle,
      expectedInitialState,
      """
      Expected first state collected to be \(expectedInitialState),
      but got \(String(describing: firstEventCollected.currentState)) instead.
      """
    )

    XCTAssertNil(
      firstEventCollected.receivedEvent,
      """
      Expected first event collected to be nil,
      but got \(String(describing: firstEventCollected)) instead.
      """
    )

    XCTAssertNil(
      firstEventCollected.newState,
      """
      Expected first new state collected to be nil,
      but got \(String(describing: firstEventCollected.newState)) instead.
      """
    )

    // When
    sut.send(event: expectedLoadingWasRequestedEvent)
    _ = await iterator.next()

    await fulfillment(of: [secondLifecycleEventWasReceived], timeout: 1.0)

    // Then
    let secondEventCollected = spy.get()[1]
    XCTAssertEqual(
      secondEventCollected.currentState as? Idle,
      expectedInitialState,
      """
      Expected second state collected to be \(expectedInitialState),
      but got \(String(describing: firstEventCollected.currentState)) instead.
      """
    )

    XCTAssertEqual(
      secondEventCollected.receivedEvent as? LoadingWasRequested,
      expectedLoadingWasRequestedEvent,
      """
      Expected second event collected to be nil,
      but got \(String(describing: firstEventCollected)) instead.
      """
    )

    XCTAssertEqual(
      secondEventCollected.newState as? Loading,
      expectedLoadingState,
      """
      Expected second new state collected to be nil,
      but got \(String(describing: firstEventCollected.newState)) instead.
      """
    )
  }

  func test_lifecycleEvents_areSerializedWhileHandlersForOneEventRunConcurrently() async {
    let initialHandlersStarted = expectation(description: "Both initial-state handlers began")
    initialHandlersStarted.expectedFulfillmentCount = 2
    let transitionHandlerRan = expectation(description: "The transition handler ran after the initial handlers")
    let gate = AsyncGate()
    let events = SendableStorage<[String]>(value: [])

    sut = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: Loading())
        }
      }
    }

    sut.onInitialState { _, _ in
      events.apply { $0.append("initial-one-began") }
      initialHandlersStarted.fulfill()
      await gate.wait()
      events.apply { $0.append("initial-one-ended") }
    }
    sut.onInitialState { _, _ in
      events.apply { $0.append("initial-two-began") }
      initialHandlersStarted.fulfill()
      await gate.wait()
      events.apply { $0.append("initial-two-ended") }
    }
    sut.onTransition { _, _, _, _ in
      events.apply { $0.append("transition") }
      transitionHandlerRan.fulfill()
    }

    var iterator = sut.makeAsyncIterator()
    _ = await iterator.next()
    await fulfillment(of: [initialHandlersStarted], timeout: 1.0)
    await sut.sendAndWait(
      event: LoadingWasRequested(id: 1701),
      until: .transitionCommitted
    )

    XCTAssertFalse(events.get().contains("transition"))

    await gate.open()
    await fulfillment(of: [transitionHandlerRan], timeout: 1.0)

    let completedEvents = events.get()
    let transitionIndex = try! XCTUnwrap(completedEvents.firstIndex(of: "transition"))
    let initialOneEndIndex = try! XCTUnwrap(completedEvents.firstIndex(of: "initial-one-ended"))
    let initialTwoEndIndex = try! XCTUnwrap(completedEvents.firstIndex(of: "initial-two-ended"))
    XCTAssertGreaterThan(transitionIndex, initialOneEndIndex)
    XCTAssertGreaterThan(transitionIndex, initialTwoEndIndex)

    await sut.finishAndWait()
  }
}

private actor AsyncGate {
  private var isOpen = false
  private var waiters: [CheckedContinuation<Void, Never>] = []

  func wait() async {
    guard !isOpen else { return }
    await withCheckedContinuation { continuation in
      if isOpen {
        continuation.resume()
      } else {
        waiters.append(continuation)
      }
    }
  }

  func open() {
    guard !isOpen else { return }
    isOpen = true
    let pendingWaiters = waiters
    waiters.removeAll()
    pendingWaiters.forEach { $0.resume() }
  }
}

// MARK: - Integration DSL support types

private struct IntegrationSuperState: Equatable, Sendable {
  let phase: String
  let count: Int
  let message: String?
  let value: String?
}

private enum IntegrationEvent { }

private struct IntegrationIdle: State, Equatable {
  var superState: IntegrationSuperState {
    .init(phase: "idle", count: 0, message: nil, value: nil)
  }
}

private struct IntegrationLoading: State, Equatable {
  let id: String
  var superState: IntegrationSuperState {
    .init(phase: "loading", count: 0, message: nil, value: nil)
  }
}

private struct IntegrationLoaded: State, Equatable {
  let value: String
  let count: Int
  var superState: IntegrationSuperState {
    .init(phase: "loaded", count: count, message: nil, value: value)
  }
}

private struct IntegrationFailed: State, Equatable {
  let message: String
  var superState: IntegrationSuperState {
    .init(phase: "failed", count: 0, message: message, value: nil)
  }
}

private struct IntegrationDidRequestLoad: Event, Equatable {
  typealias SuperEvent = IntegrationEvent
  let id: String
}

private struct IntegrationDidSucceed: Event, Equatable {
  typealias SuperEvent = IntegrationEvent
  let value: String
}

private struct IntegrationDidFail: Event, Equatable {
  typealias SuperEvent = IntegrationEvent
  let message: String
}

private struct IntegrationTick: Event, Equatable {
  typealias SuperEvent = IntegrationEvent
}

private struct IntegrationError: Error {
  let attempt: Int
}

private struct IntegrationLoad: Sendable {
  let dependency: @Sendable (String) async throws -> String

  init(dependency: @Sendable @escaping (String) async throws -> String) {
    self.dependency = dependency
  }

  func callAsFunction(eventId: String) -> @Sendable () async throws -> (any Event<IntegrationEvent>)? {
    {
      let value = try await dependency(eventId)
      return IntegrationDidSucceed(value: value)
    }
  }
}

private struct IntegrationPoll: Sendable {
  let dependency: @Sendable () async -> String

  init(dependency: @Sendable @escaping () async -> String) {
    self.dependency = dependency
  }

  func callAsFunction() -> @Sendable () async -> (any Event<IntegrationEvent>)? {
    {
      _ = await dependency()
      return IntegrationTick()
    }
  }
}

private struct IntegrationClock {
  let sleep: @Sendable (Duration) async -> Void

  init(sleep: @Sendable @escaping (Duration) async -> Void) {
    self.sleep = sleep
  }
}
