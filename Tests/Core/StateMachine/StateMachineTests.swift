import StateMachineShared
import XCTest
@testable import StateMachineCore

// MARK: - StateMachineTests

// swiftlint:disable file_length
// swiftlint:disable implicitly_unwrapped_optional

final class StateMachineTests: XCTestCase {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    sut = StateMachine<MockSuperState, MockSuperEvent>(initial: TestedState.idle)
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: StateMachine<MockSuperState, MockSuperEvent>!

  // MARK: - Methods

  func test_init_withInitialState_setsInitialState() {
    let expected = Loaded(value: 1701)
    sut = StateMachine<MockSuperState, MockSuperEvent>(initial: expected)

    let received = sut.initial as? Loaded
    XCTAssertEqual(
      received,
      expected,
      "Expectedi initial state to be \(expected), but got \(String(describing: received)) instead."
    )
  }
}

// MARK: tests for `when(oneOfStates:oneOfEvents:guard:mealyTransition)`

extension StateMachineTests {
  func test_when_whenOneOfStatesOnOneOfEvents_registersMealyTransitionReturningExpectedStateTransition() async {
    let expectedStates: [any State<MockSuperState>] = [
      TestedState.idle,
      TestedState.loaded,
    ]
    let expectedEvents: [any Event<MockSuperEvent>] = [
      TestedEvent.loadingRequestedWithValue1701,
      TestedEvent.reloadingRequestedWithValue1702,
    ]

    let receivedState = SendableStorage<(any State<MockSuperState>)?>(value: nil)
    let receivedEvent = SendableStorage<(any Event<MockSuperEvent>)?>(value: nil)

    let expectedNextState = TestedState.loading

    // Given
    sut = sut
      // When
        .when(
          OneOfStates(Idle.self, Loaded.self),
          on: OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
        ) { state, event in
          receivedState.set(value: state)
          receivedEvent.set(value: event)

          return MealyTransition(transition: Transition(state: expectedNextState), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 4
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    for expectedState in expectedStates {
      for expectedEvent in expectedEvents {
        await assertTransition(
          stateMachine: sut,
          when: expectedState,
          on: expectedEvent,
          nextState: expectedNextState,
          spyInputState: receivedState,
          spyInputEvent: receivedEvent
        )

        receivedState.set(value: nil)
        receivedEvent.set(value: nil)
      }
    }
  }

  func test_when_whenOneOfStatesOnOneOfEvents_registersMealyTransitionReturningNilWhenUnexpectedStateType(
  ) async throws {
    // Given
    sut = sut
      // When
        .when(
          OneOfStates(Idle.self, Loaded.self),
          on: OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
        ) { _, _ in
          MealyTransition(transition: Transition(state: TestedState.loading), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 4
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertNoTransition(
      stateMachine: sut,
      when: TestedState.loading,
      on: TestedEvent.loadingRequestedWithValue1701
    )
    try await assertNoOutput(
      stateMachine: sut,
      when: TestedState.loading,
      on: TestedEvent.loadingRequestedWithValue1701
    )
  }

  func test_when_whenOneOfStatesOnOneOfEvents_registersMealyTransitionReturningNilWhenUnexpectedInputEventType(
  ) async throws {
    // Given
    sut = sut
      // When
        .when(
          OneOfStates(Idle.self, Loaded.self),
          on: OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
        ) { _, _ in
          MealyTransition(transition: Transition(state: TestedState.loading), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 4
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertNoTransition(
      stateMachine: sut,
      when: TestedState.idle,
      on: TestedEvent.loadingSucceededWithValue1701
    )
    try await assertNoOutput(
      stateMachine: sut,
      when: TestedState.idle,
      on: TestedEvent.loadingSucceededWithValue1701
    )
  }

  func test_when_whenOneOfStatesOnOneOfEvents_registersGuardedMealyTransition() async throws {
    let expectedState = TestedState.idle
    let expectedEvent = TestedEvent.loadingRequestedWithValue1701

    let receivedState = SendableStorage<(any State<MockSuperState>)?>(value: nil)
    let receivedEvent = SendableStorage<(any Event<MockSuperEvent>)?>(value: nil)

    // Given
    sut = sut
      // When
        .when(
          OneOfStates(Idle.self, Loaded.self),
          on: OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
        ) { state, event in
          receivedState.set(value: state)
          receivedEvent.set(value: event)

          return false
        } mealyTransition: { _, _ in
          MealyTransition(transition: Transition(state: TestedState.loading), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 4
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertNoTransition(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent
    )
    try await assertNoOutput(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent
    )

    receivedState.assertEqual(expected: expectedState)
    receivedEvent.assertEqual(expected: expectedEvent)
  }

  func test_when_whenOneOfStatesOnOneOfEvents_registersMealyTransitionReturningAnOutputFromASideEffect(
  ) async throws {
    let expectedState = TestedState.idle
    let expectedEvent = TestedEvent.loadingRequestedWithValue1701

    let sideEffectIsCalled = SendableStorage<Bool>(value: false)

    let output = Output<MockSuperState, MockSuperEvent> {
      sideEffectIsCalled.set(value: true)
      return nil
    }

    // Given
    sut = sut
      // When
        .when(
          OneOfStates(Idle.self, Loaded.self),
          on: OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
        ) { _, _ in
          MealyTransition(transition: Transition(state: TestedState.loading), output: output)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 4
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    try await assertOutput(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent,
      spyOutput: sideEffectIsCalled
    )
  }
}

// MARK: tests for `when(state:oneOfEvents:guard:mealyTransition)`

extension StateMachineTests {
  func test_when_whenStateOnOneOfEvents_registersMealyTransitionReturningExpectedStateTransition() async {
    let expectedState = TestedState.idle
    let expectedEvent = TestedEvent.loadingRequestedWithValue1701

    let receivedState = SendableStorage<(any State<MockSuperState>)?>(value: nil)
    let receivedEvent = SendableStorage<(any Event<MockSuperEvent>)?>(value: nil)

    let expectedNextState = TestedState.loading

    // Given
    sut = sut
      // When
        .when(
          state: Idle.self,
          on: OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
        ) { state, event in
          receivedState.set(value: state)
          receivedEvent.set(value: event)

          return MealyTransition(transition: Transition(state: expectedNextState), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 2
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertTransition(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent,
      nextState: expectedNextState,
      spyInputState: receivedState,
      spyInputEvent: receivedEvent
    )
  }

  func test_when_whenStateOnOneOfEvents_registersMealyTransitionReturningNilWhenUnexpectedInputStateType(
  ) async throws {
    // Given
    sut = sut
      // When
        .when(
          state: Idle.self,
          on: OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
        ) { _, _ in
          MealyTransition(transition: Transition(state: TestedState.loading), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 2
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertNoTransition(
      stateMachine: sut,
      when: TestedState.loading,
      on: TestedEvent.loadingRequestedWithValue1701
    )
    try await assertNoOutput(
      stateMachine: sut,
      when: TestedState.loading,
      on: TestedEvent.loadingRequestedWithValue1701
    )
  }

  func test_when_whenStateOnOneOfEvents_registersGuardedMealyTransitionHappening() async throws {
    let expectedState = TestedState.idle
    let expectedEvent = TestedEvent.loadingRequestedWithValue1701

    let receivedState = SendableStorage<(any State<MockSuperState>)?>(value: nil)
    let receivedEvent = SendableStorage<(any Event<MockSuperEvent>)?>(value: nil)

    // Given
    sut = sut
      // When
        .when(
          state: Idle.self,
          on: OneOfEvents(LoadingWasRequested.self, ReloadingWasRequested.self)
        ) { state, event in
          receivedState.set(value: state)
          receivedEvent.set(value: event)

          return false
        } mealyTransition: { _, _ in
          MealyTransition(transition: Transition(state: TestedState.loading), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 2
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertNoTransition(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent
    )
    try await assertNoOutput(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent
    )

    receivedState.assertEqual(expected: expectedState)
    receivedEvent.assertEqual(expected: expectedEvent)
  }
}

// MARK: tests for `when(oneOfStates:on:guard:mealyTransition)`

extension StateMachineTests {
  func test_when_whenOneOfStatesOnEvent_registersMealyTransitionReturningExpectedStateTransition() async {
    let expectedState = TestedState.idle
    let expectedEvent = TestedEvent.loadingRequestedWithValue1701

    let receivedState = SendableStorage<(any State<MockSuperState>)?>(value: nil)
    let receivedEvent = SendableStorage<(any Event<MockSuperEvent>)?>(value: nil)

    let expectedNextState = TestedState.loading

    // Given
    sut = sut
      // When
        .when(
          OneOfStates(Idle.self, Loaded.self),
          on: LoadingWasRequested.self
        ) { state, event in
          receivedState.set(value: state)
          receivedEvent.set(value: event)

          return MealyTransition(transition: Transition(state: expectedNextState), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 2
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertTransition(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent,
      nextState: expectedNextState,
      spyInputState: receivedState,
      spyInputEvent: receivedEvent
    )
  }

  func test_when_whenOneOfStatesOnEvent_registersMealyTransitionReturningNilWhenUnexpectedInputStateType(
  ) async throws {
    // Given
    sut = sut
      // When
        .when(
          OneOfStates(Idle.self, Loaded.self),
          on: LoadingWasRequested.self
        ) { _, _ in
          MealyTransition(transition: Transition(state: TestedState.loading), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 2
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertNoTransition(
      stateMachine: sut,
      when: TestedState.loading,
      on: TestedEvent.loadingRequestedWithValue1701
    )
    try await assertNoOutput(
      stateMachine: sut,
      when: TestedState.loading,
      on: TestedEvent.loadingRequestedWithValue1701
    )
  }

  func test_when_whenOneOfStatesOnEvent_registersGuardedMealyTransition() async throws {
    let expectedState = TestedState.idle
    let expectedEvent = TestedEvent.loadingRequestedWithValue1701

    let receivedState = SendableStorage<(any State<MockSuperState>)?>(value: nil)
    let receivedEvent = SendableStorage<(any Event<MockSuperEvent>)?>(value: nil)

    // Given
    sut = sut
      // When
        .when(
          OneOfStates(Idle.self, Loaded.self),
          on: LoadingWasRequested.self
        ) { state, event in
          receivedState.set(value: state)
          receivedEvent.set(value: event)

          return false
        } mealyTransition: { _, _ in
          MealyTransition(transition: Transition(state: TestedState.loading), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 2
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertNoTransition(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent
    )
    try await assertNoOutput(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent
    )

    receivedState.assertEqual(expected: expectedState)
    receivedEvent.assertEqual(expected: expectedEvent)
  }
}

// MARK: tests for `when(state:on:guard:mealyTransition)`

extension StateMachineTests {
  func test_when_whenStateOnEvent_registersMealyTransitionReturningExpectedStateTransition() async {
    let expectedState = TestedState.idle
    let expectedEvent = TestedEvent.loadingRequestedWithValue1701

    let receivedState = SendableStorage<(any State<MockSuperState>)?>(value: nil)
    let receivedEvent = SendableStorage<(any Event<MockSuperEvent>)?>(value: nil)

    let expectedNextState = TestedState.loading

    // Given
    sut = sut
      // When
        .when(
          state: Idle.self,
          on: LoadingWasRequested.self
        ) { state, event in
          receivedState.set(value: state)
          receivedEvent.set(value: event)

          return MealyTransition(transition: Transition(state: expectedNextState), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 1
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertTransition(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent,
      nextState: expectedNextState,
      spyInputState: receivedState,
      spyInputEvent: receivedEvent
    )
  }

  func test_when_whenStateOnEvent_registersMealyTransitionReturningNilWhenUnexpectedInputStateType() async throws {
    // Given
    sut = sut
      // When
        .when(
          state: Idle.self,
          on: LoadingWasRequested.self
        ) { _, _ in
          MealyTransition(transition: Transition(state: TestedState.loading), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 1
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertNoTransition(
      stateMachine: sut,
      when: TestedState.loading,
      on: TestedEvent.loadingRequestedWithValue1701
    )
    try await assertNoOutput(
      stateMachine: sut,
      when: TestedState.loading,
      on: TestedEvent.loadingRequestedWithValue1701
    )
  }

  func test_when_whenStateOnEvent_registersGuardedMealyTransition() async throws {
    let expectedState = TestedState.idle
    let expectedEvent = TestedEvent.loadingRequestedWithValue1701

    let receivedState = SendableStorage<(any State<MockSuperState>)?>(value: nil)
    let receivedEvent = SendableStorage<(any Event<MockSuperEvent>)?>(value: nil)

    // Given
    sut = sut
      // When
        .when(
          state: Idle.self,
          on: LoadingWasRequested.self
        ) { state, event in
          receivedState.set(value: state)
          receivedEvent.set(value: event)

          return false
        } mealyTransition: { _, _ in
          MealyTransition(transition: Transition(state: TestedState.loading), output: nil)
        }

    // Then
    let mealyTableCount = sut.mealyTable.count
    let expectedMealyTableCount = 1
    XCTAssertEqual(
      mealyTableCount,
      expectedMealyTableCount,
      "Expected mealy table count of \(expectedMealyTableCount), but got \(mealyTableCount) instead."
    )

    await assertNoTransition(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent
    )
    try await assertNoOutput(
      stateMachine: sut,
      when: expectedState,
      on: expectedEvent
    )

    receivedState.assertEqual(expected: expectedState)
    receivedEvent.assertEqual(expected: expectedEvent)
  }
}

// MARK: tests for `transition(state:event:)`

extension StateMachineTests {
  func test_transition_whenUnreferencedIdentifiers_returnsNil() async {
    // Given a state machine with initial state `Idle()`

    // When
    let mealyTransition = await sut.transition(
      state: TestedState.idle,
      event: TestedEvent.loadingRequestedWithValue1701
    )

    // Then
    XCTAssertNil(
      mealyTransition,
      "Expected mealy transition to be `nil`, but got \(String(describing: mealyTransition)) instead."
    )
  }

  func test_transition_whenNoMatchingResult_returnsNil() async throws {
    let output = Output<MockSuperState, MockSuperEvent> {
      nil
    }

    // Given
    sut = sut
      .when(state: Idle.self, on: LoadingWasRequested.self) { _, _ in
        false
      } mealyTransition: { _, _ in
        MealyTransition(transition: Transition(state: TestedState.loading), output: output)
      }

    // When
    let mealyTransition = await sut.transition(
      state: TestedState.idle,
      event: TestedEvent.loadingRequestedWithValue1701
    )

    // Then
    XCTAssertNil(
      mealyTransition,
      "Expected mealy transition to be `nil`, but got \(String(describing: mealyTransition)) instead."
    )
  }

  func test_transition_whenReferencedIdentifiers_returnsFirstMatchingResult() async throws {
    let expectedState = TestedState.loading

    let transition1IsCalled = SendableStorage(value: false)
    let sideEffect1IsCalled = SendableStorage(value: false)

    let transition2IsCalled = SendableStorage(value: false)
    let sideEffect2IsCalled = SendableStorage(value: false)

    let output1 = Output<MockSuperState, MockSuperEvent> {
      sideEffect1IsCalled.set(value: true)
      return nil
    }

    let output2 = Output<MockSuperState, MockSuperEvent> {
      sideEffect2IsCalled.set(value: true)
      return nil
    }

    // Given
    sut = sut
      .when(state: Idle.self, on: LoadingWasRequested.self, guard: { _, _ in false }) { _, _ in
        transition1IsCalled.set(value: true)
        return MealyTransition(transition: Transition(state: expectedState), output: output1)
      }
      .when(state: Idle.self, on: LoadingWasRequested.self, guard: { _, _ in true }) { _, _ in
        transition2IsCalled.set(value: true)
        return MealyTransition(transition: Transition(state: expectedState), output: output2)
      }

    // When
    let mealyTransition = await sut.transition(
      state: TestedState.idle,
      event: TestedEvent.loadingRequestedWithValue1701
    )
    let receivedTransition = mealyTransition?.transition
    let receivedOutput = mealyTransition?.output

    // Then
    let receivedState = await receivedTransition?.state()
    let receivedStateTyped = receivedState as? Loading
    XCTAssertEqual(
      receivedStateTyped,
      expectedState,
      """
      Expected the state received to be \(expectedState), but got \(String(describing: receivedStateTyped)) instead.
      """
    )
    let receivedSequence = await receivedOutput?.sideEffect()
    for try await _ in receivedSequence.unsafelyUnwrapped { }

    transition1IsCalled.assertEqual(expected: false)
    transition2IsCalled.assertEqual(expected: true)

    sideEffect1IsCalled.assertEqual(expected: false)
    sideEffect2IsCalled.assertEqual(expected: true)
  }
}

// MARK: tooling

extension StateMachineTests {

  // swiftlint:disable:next function_parameter_count
  private func assertTransition<SuperState, SuperEvent, NS: State & Equatable>(
    stateMachine: StateMachine<SuperState, SuperEvent>,
    when state: some State<SuperState>,
    on event: some Event<SuperEvent>,
    nextState: NS,
    spyInputState: SendableStorage<(any State<SuperState>)?>,
    spyInputEvent: SendableStorage<(any Event<SuperEvent>)?>
  ) async where NS.SuperState == SuperState {
    let identifier = TypesIdentifier(lhsValue: state, rhsValue: event)

    guard let mealyTransitions = stateMachine.mealyTable[identifier] else {
      XCTFail("Expected a non `nil` mealy transition for the state \(state) and the event \(event)")
      return
    }

    var receivedTransition: Transition<SuperState>?

    for transition in mealyTransitions {
      if let result = await transition(state, event)?.transition {
        receivedTransition = result
        break
      }
    }

    guard let transition = receivedTransition else {
      XCTFail("Expected a non `nil` transition for the state \(state) and the event \(event)")
      return
    }

    let receivedNextState = await transition.state()

    let receivedNextStateTyped = receivedNextState as? NS
    XCTAssertEqual(
      receivedNextStateTyped,
      nextState,
      "Expected next state to be \(nextState) but got \(String(describing: receivedNextStateTyped)) instead."
    )

    spyInputState.assertEqual(expected: state)
    spyInputEvent.assertEqual(expected: event)
  }

  private func assertNoTransition<SuperState, SuperEvent>(
    stateMachine: StateMachine<SuperState, SuperEvent>,
    when state: some State<SuperState>,
    on event: some Event<SuperEvent>
  ) async {
    let identifier = TypesIdentifier(lhsValue: state, rhsValue: event)

    if let mealyTransitions = stateMachine.mealyTable[identifier] {
      var receivedTransition: Transition<SuperState>?

      for transition in mealyTransitions {
        if let result = await transition(state, event)?.transition {
          receivedTransition = result
          break
        }
      }

      XCTAssertNil(
        receivedTransition,
        """
        Expected teh mealy transition to be `nil` for the state \(state) and the event \(event),
        but got \(String(describing: receivedTransition)) instead.
        """
      )
    }
  }

  private func assertOutput<SuperState, SuperEvent>(
    stateMachine: StateMachine<SuperState, SuperEvent>,
    when state: some State<SuperState>,
    on event: some Event<SuperEvent>,
    spyOutput: SendableStorage<Bool>
  ) async throws {
    let identifier = TypesIdentifier(lhsValue: state, rhsValue: event)

    guard let mealyTransitions = stateMachine.mealyTable[identifier] else {
      XCTFail("Expected a non `nil` output for the state \(state) and the event \(event).")
      return
    }

    var receivedOutput: Output<SuperState, SuperEvent>?

    for transition in mealyTransitions {
      if let result = await transition(state, event)?.output {
        receivedOutput = result
        break
      }
    }

    guard let output = receivedOutput else {
      XCTFail("Expected a non nil output for the state \(state) and the event \(event).")
      return
    }

    let sequence = await output.sideEffect()

    for try await _ in sequence { }
    spyOutput.assertEqual(expected: true)
  }

  private func assertNoOutput<SuperState, SuperEvent>(
    stateMachine: StateMachine<SuperState, SuperEvent>,
    when state: some State<SuperState>,
    on event: some Event<SuperEvent>
  ) async throws {
    let identifier = TypesIdentifier(lhsValue: state, rhsValue: event)

    if let mealyTransitions = stateMachine.mealyTable[identifier] {
      var receivedOutput: Output<SuperState, SuperEvent>?

      for transition in mealyTransitions {
        if let result = await transition(state, event)?.output {
          receivedOutput = result
          break
        }
      }

      XCTAssertNil(receivedOutput, "Expected a `nil` output for the state \(state) and the event \(event)")
    }
  }
}
