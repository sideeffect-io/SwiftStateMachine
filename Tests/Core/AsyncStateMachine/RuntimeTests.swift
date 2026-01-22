import StateMachineShared
import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional
// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

final class RuntimeTests: XCTestCase, @unchecked Sendable {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = Runtime<MockSuperState, MockSuperEvent>()
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: Runtime<MockSuperState, MockSuperEvent>!

  // MARK: - Methods

  func test_execute_runsSideEffectAndCallsFeedbackAndCleansStorage() async {
    let sideEffectCanFinish = expectation(description: "The side effect is authorized to finish")

    let expectedEvent = TestedEvent.loadingSucceededWithValue1701
    let feedbackIsCalledWithEvent = SendableStorage<(any Event<MockSuperEvent>)?>(value: nil)

    // Given
    let output = Output<MockSuperState, MockSuperEvent> {
      await self.fulfillment(of: [sideEffectCanFinish], timeout: 1.0)
      XCTAssertFalse(Task.isCancelled)
      return expectedEvent
    }

    let spyFeedback: @Sendable (any Event<MockSuperEvent>) async -> Void = { event in
      feedbackIsCalledWithEvent.set(value: event)
    }

    // When
    let removalTask = await sut.execute(output: output, feedback: spyFeedback)

    // Then
    let tasksInProgressBeforeEndOfSideEffect = await sut.tasksInProgress.count
    XCTAssertEqual(tasksInProgressBeforeEndOfSideEffect, 1)

    sideEffectCanFinish.fulfill()

    await removalTask.value
    let tasksInProgressAfterEndOfSideEffect = await sut.tasksInProgress.count
    XCTAssertEqual(tasksInProgressAfterEndOfSideEffect, 0)

    feedbackIsCalledWithEvent.assertEqual(expected: expectedEvent)
  }

  func test_execute_sideEffectWithPriority_runsSideEffectWithPriority() async {
    let expectedPriority = TaskPriority.background
    let receivedPriority = SendableStorage<TaskPriority?>(value: nil)

    // Given
    let output = Output<MockSuperState, MockSuperEvent>(priority: .high) {
      receivedPriority.set(value: Task.currentPriority)
      return nil
    }

    // When
    _ = await sut.execute(output: output, feedback: { _ in }).value

    // Then
    let collectedPriority = receivedPriority.get()
    XCTAssert(
      collectedPriority!.rawValue >= expectedPriority.rawValue,
      """
      Expected the collected priority to be superior or equal to the \(expectedPriority.rawValue),
      but got \(collectedPriority!.rawValue) instead.
      """
    )
  }

  func test_execute_whenLifecyclePolicyRestartsOnCompletion_restartsSideEffect() async {
    let runCount = SendableStorage(value: 0)
    let feedbackCount = SendableStorage(value: 0)

    let output = Output<MockSuperState, MockSuperEvent>(
      sideEffect: {
        AsyncStream { continuation in
          runCount.apply { $0 += 1 }
          continuation.yield(TestedEvent.loadingSucceededWithValue1701)
          continuation.finish()
        }
      },
      lifecyclePolicy: .restartOnCompletion(maxRestarts: 1)
    )

    let removalTask = await sut.execute(
      output: output,
      feedback: { _ in feedbackCount.apply { $0 += 1 } }
    )

    await removalTask.value

    runCount.assertEqual(expected: 2)
    feedbackCount.assertEqual(expected: 2)
  }

  func test_execute_whenLifecyclePolicyRestartsOnFailure_emitsFailureEventAndRestarts() async {
    enum TestError: Error { case failure }
    let feedbackCount = SendableStorage(value: 0)

    let output = Output<MockSuperState, MockSuperEvent>(
      sideEffect: {
        AsyncThrowingStream { continuation in
          continuation.finish(throwing: TestError.failure)
        }
      },
      lifecyclePolicy: .restartOnFailure(maxRestarts: 1),
      onFailure: { _ in TestedEvent.loadingFailed }
    )

    let removalTask = await sut.execute(
      output: output,
      feedback: { _ in feedbackCount.apply { $0 += 1 } }
    )

    await removalTask.value

    feedbackCount.assertEqual(expected: 2)
  }

  func test_cancel_cancelsTasksAndCleansStorage() {
    let sideEffectIsRunning = expectation(description: "The side effect is currently running")
    let sideEffectWasCancelled = expectation(description: "The side effect was cancelled")
    let tasksAreFinished = expectation(description: "All the tasks have finished")
    tasksAreFinished.expectedFulfillmentCount = 2

    // Given
    let output = Output<MockSuperState, MockSuperEvent> {
      await suspendedSideEffect(
        onSuspended: { sideEffectIsRunning.fulfill() },
        onCancel: { sideEffectWasCancelled.fulfill() },
        resumeWith: { nil }
      )
    }.cancellationPolicy(cancel: Cancel(whencurrentState: Loading.self, on: ReloadingWasRequested.self))

    Task {
      await sut.execute(output: output, feedback: { _ in })
      let tasksInProgressBeforeCancel = await sut.tasksInProgress.count
      let expectedNumberOfTasksInProgressBeforeCancel = 1
      XCTAssertEqual(
        tasksInProgressBeforeCancel,
        expectedNumberOfTasksInProgressBeforeCancel,
        """
        Expected number of tasks in progress before cancellation to be \(expectedNumberOfTasksInProgressBeforeCancel),
        but got \(tasksInProgressBeforeCancel) instead.
        """
      )
      tasksAreFinished.fulfill()
    }

    wait(for: [sideEffectIsRunning], timeout: 1.0)

    // When
    Task {
      await sut.cancel(
        currentState: TestedState.loading,
        event: TestedEvent.reloadingRequestedWithValue1701,
        newState: TestedState.loaded
      )
      let tasksInProgressAfterCancel = await sut.tasksInProgress.count
      let expectedNumberOfTasksInProgressAfterCancel = 0
      XCTAssertEqual(
        tasksInProgressAfterCancel,
        expectedNumberOfTasksInProgressAfterCancel,
        """
        Expected number of tasks in progress after cancellation to be \(expectedNumberOfTasksInProgressAfterCancel),
        but got \(tasksInProgressAfterCancel) instead.
        """
      )
      tasksAreFinished.fulfill()
    }

    // Then
    wait(for: [sideEffectWasCancelled], timeout: 1.0)
    wait(for: [tasksAreFinished], timeout: 1.0)
  }

  func test_cancel_whenNoCancellationPolicy_doesNotCancelTask() {
    let sideEffectIsRunning = expectation(description: "The side effect is currently running")
    let tasksAreFinished = expectation(description: "All the tasks have finished")
    tasksAreFinished.expectedFulfillmentCount = 2

    let isCancelled = SendableStorage(value: false)

    // Given
    let output = Output<MockSuperState, MockSuperEvent> {
      await suspendedSideEffect(
        onSuspended: { sideEffectIsRunning.fulfill() },
        onCancel: { isCancelled.set(value: true) },
        resumeWith: { nil }
      )
    }

    // When
    Task {
      await sut.execute(output: output, feedback: { _ in })
      let tasksInProgressBeforeCancel = await sut.tasksInProgress.count
      let expectedNumberOfTasksInProgressBeforeCancel = 1
      XCTAssertEqual(
        tasksInProgressBeforeCancel,
        expectedNumberOfTasksInProgressBeforeCancel,
        """
        Expected number of tasks in progress before cancellation to be \(expectedNumberOfTasksInProgressBeforeCancel),
        but got \(tasksInProgressBeforeCancel) instead.
        """
      )
      tasksAreFinished.fulfill()
    }

    wait(for: [sideEffectIsRunning], timeout: 1.0)

    // When
    Task {
      await sut.cancel(
        currentState: TestedState.loading,
        event: TestedEvent.reloadingRequestedWithValue1701,
        newState: TestedState.loaded
      )
      let tasksInProgressBeforeCancel = await sut.tasksInProgress.count
      let expectedNumberOfTasksInProgressBeforeCancel = 1
      XCTAssertEqual(
        tasksInProgressBeforeCancel,
        expectedNumberOfTasksInProgressBeforeCancel,
        """
        Expected number of tasks in progress before cancellation to be \(expectedNumberOfTasksInProgressBeforeCancel),
        but got \(tasksInProgressBeforeCancel) instead.
        """
      )
      tasksAreFinished.fulfill()
    }

    // Then
    wait(for: [tasksAreFinished], timeout: 1.0)

    isCancelled.assertEqual(expected: false)
  }

  func test_cancelAll_cancelsAllTasks() {
    let sideEffectsAreRunning = expectation(description: "The side effects are currently running")
    sideEffectsAreRunning.expectedFulfillmentCount = 2
    let sideEffectsWereCancelled = expectation(description: "The side effects were cancelled")
    sideEffectsWereCancelled.expectedFulfillmentCount = 2
    let tasksAreFinished = expectation(description: "All the tasks have finished")
    tasksAreFinished.expectedFulfillmentCount = 2

    // Given
    let output1 = Output<MockSuperState, MockSuperEvent> {
      await suspendedSideEffect(
        onSuspended: { sideEffectsAreRunning.fulfill() },
        onCancel: { sideEffectsWereCancelled.fulfill() },
        resumeWith: { nil }
      )
    }

    let output2 = Output<MockSuperState, MockSuperEvent> {
      await suspendedSideEffect(
        onSuspended: { sideEffectsAreRunning.fulfill() },
        onCancel: { sideEffectsWereCancelled.fulfill() },
        resumeWith: { nil }
      )
    }

    let sut = Runtime<MockSuperState, MockSuperEvent>()

    Task {
      await sut.execute(output: output1, feedback: { _ in })
      await sut.execute(output: output2, feedback: { _ in })
      let tasksInProgress = await sut.tasksInProgress

      let numberOfTasksInProgress = tasksInProgress.count
      let expectedNumberOfTasksInProgress = 2
      XCTAssertEqual(
        numberOfTasksInProgress,
        expectedNumberOfTasksInProgress,
        """
        Expected number of tasks in progress to be \(expectedNumberOfTasksInProgress),
        but got \(numberOfTasksInProgress) instead.
        """
      )

      tasksAreFinished.fulfill()
    }

    wait(for: [sideEffectsAreRunning], timeout: 1.0)

    // When
    Task {
      await sut.cancelAll()
      let tasksInProgress = await sut.tasksInProgress

      let numberOfTasksInProgress = tasksInProgress.count
      let expectedNumberOfTasksInProgress = 0
      XCTAssertEqual(
        numberOfTasksInProgress,
        expectedNumberOfTasksInProgress,
        """
        Expected number of tasks in progress to be \(expectedNumberOfTasksInProgress),
        but got \(numberOfTasksInProgress) instead.
        """
      )
      tasksAreFinished.fulfill()
    }

    // Then
    wait(for: [sideEffectsWereCancelled], timeout: 1.0)
    wait(for: [tasksAreFinished], timeout: 1.0)
  }

  func test_execute_runsOnInitialStatesAndCleansStorage() async {
    let onInitialStateCanFinish = expectation(description: "The side effect is authorized to finish")

    let expectedId = UUID()
    let expectedInitialState = TestedState.idle

    let receivedId = SendableStorage<UUID?>(value: nil)
    let receivedInitialState = SendableStorage<Idle?>(value: nil)

    // Given
    let onInitialState: AsyncStateMachine<MockSuperState, MockSuperEvent>.OnInitialState = { id, initialState in
      await self.fulfillment(of: [onInitialStateCanFinish], timeout: 1.0)
      receivedId.set(value: id)
      receivedInitialState.set(value: initialState as? Idle)
    }

    // When
    let removalTask = await sut.execute(
      onInitialStates: [onInitialState],
      id: expectedId,
      initialState: expectedInitialState
    )

    // Then
    let tasksInProgressBeforeEnd = await sut.tasksInProgress.count
    let expectedNumberOfTasksInProgressBeforeEnd = 1
    XCTAssertEqual(
      tasksInProgressBeforeEnd,
      expectedNumberOfTasksInProgressBeforeEnd,
      """
      Expected number of tasks in progress before end of onInitialState to be
      \(expectedNumberOfTasksInProgressBeforeEnd), but got \(tasksInProgressBeforeEnd) instead.
      """
    )

    onInitialStateCanFinish.fulfill()

    await removalTask.value
    let tasksInProgressAfterEnd = await sut.tasksInProgress.count
    let expectedNumberOfTasksInProgressAfterEnd = 0
    XCTAssertEqual(
      tasksInProgressAfterEnd,
      expectedNumberOfTasksInProgressAfterEnd,
      """
      Expected number of tasks in progress after end of onInitialState to be
      \(expectedNumberOfTasksInProgressAfterEnd), but got \(tasksInProgressAfterEnd) instead.
      """
    )

    receivedId.assertEqual(expected: expectedId)
    receivedInitialState.assertEqual(expected: expectedInitialState)
  }

  func test_execute_runsOnTransitionsAndCleansStorage() async {
    let middlewareCanFinish = expectation(description: "The side effect is authorized to finish")

    let expectedId = UUID()
    let expectedCurrentState = TestedState.idle
    let expectedEvent = TestedEvent.loadingSucceededWithValue1701
    let expectedNewState = TestedState.loading

    let receivedId = SendableStorage<UUID?>(value: nil)
    let receivedCurrentState = SendableStorage<Idle?>(value: nil)
    let receivedEvent = SendableStorage<LoadingHasSucceeded?>(value: nil)
    let receivedNewState = SendableStorage<Loading?>(value: nil)

    // Given
    let onTransition: AsyncStateMachine<MockSuperState, MockSuperEvent>.OnTransition = { id, current, event, new in
      await self.fulfillment(of: [middlewareCanFinish], timeout: 1.0)
      receivedId.set(value: id)
      receivedCurrentState.set(value: current as? Idle)
      receivedEvent.set(value: event as? LoadingHasSucceeded)
      receivedNewState.set(value: new as? Loading)
    }

    // When
    let removalTask = await sut.execute(
      onTransitions: [onTransition],
      id: expectedId,
      currentState: expectedCurrentState,
      on: expectedEvent,
      newState: expectedNewState
    )

    // Then
    let tasksInProgressBeforeEnd = await sut.tasksInProgress.count
    let expectedNumberOfTasksInProgressBeforeEnd = 1
    XCTAssertEqual(
      tasksInProgressBeforeEnd,
      expectedNumberOfTasksInProgressBeforeEnd,
      """
      Expected number of tasks in progress before end of onTransition to be
      \(expectedNumberOfTasksInProgressBeforeEnd), but got \(tasksInProgressBeforeEnd) instead.
      """
    )

    middlewareCanFinish.fulfill()

    await removalTask.value
    let tasksInProgressAfterEnd = await sut.tasksInProgress.count
    let expectedNumberOfTasksInProgressAfterEnd = 0
    XCTAssertEqual(
      tasksInProgressAfterEnd,
      expectedNumberOfTasksInProgressAfterEnd,
      """
      Expected number of tasks in progress After end of onTransition to be
      \(expectedNumberOfTasksInProgressAfterEnd), but got \(tasksInProgressAfterEnd) instead.
      """
    )

    receivedId.assertEqual(expected: expectedId)
    receivedCurrentState.assertEqual(expected: expectedCurrentState)
    receivedEvent.assertEqual(expected: expectedEvent)
    receivedNewState.assertEqual(expected: expectedNewState)
  }

  func test_deinit_cancelsTasks() {
    let sideEffectsAreRunning = expectation(description: "The side effects are currently running")
    sideEffectsAreRunning.expectedFulfillmentCount = 2
    let sideEffectsWereCancelled = expectation(description: "The side effects were cancelled")
    sideEffectsWereCancelled.expectedFulfillmentCount = 2
    let taskIsFinished = expectation(description: "The execution task is finished")

    // Given
    let output1 = Output<MockSuperState, MockSuperEvent> {
      await suspendedSideEffect(
        onSuspended: { sideEffectsAreRunning.fulfill() },
        onCancel: { sideEffectsWereCancelled.fulfill() },
        resumeWith: { nil }
      )
    }

    let output2 = Output<MockSuperState, MockSuperEvent> {
      await suspendedSideEffect(
        onSuspended: { sideEffectsAreRunning.fulfill() },
        onCancel: { sideEffectsWereCancelled.fulfill() },
        resumeWith: { nil }
      )
    }

    var sut: Runtime<MockSuperState, MockSuperEvent>? = Runtime()

    Task { [sut] in
      await sut?.execute(output: output1, feedback: { _ in })
      await sut?.execute(output: output2, feedback: { _ in })
      let tasksInProgress = await sut?.tasksInProgress

      let numberOfTasksInProgress = tasksInProgress!.count
      let expectedNumberOfTasksInProgress = 2
      XCTAssertEqual(
        numberOfTasksInProgress,
        expectedNumberOfTasksInProgress,
        """
        Expected number of tasks in progress to be \(expectedNumberOfTasksInProgress),
        but got \(numberOfTasksInProgress) instead.
        """
      )
      taskIsFinished.fulfill()
    }

    wait(
      for: [
        sideEffectsAreRunning,
      ],
      timeout: 1.0
    )

    // When
    sut = nil

    // Then
    wait(
      for: [
        sideEffectsWereCancelled,
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
}
