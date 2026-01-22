// swiftlint:disable:this file_name

#if DEBUG
import StateMachineCore
import StateMachineShared
import XCTestDynamicOverlay

// MARK: Public

// Asserts that an ``AsyncStateMachine`` produces the expected states in regards to the given events.
/// - Parameters:
///   - asyncStateMachine: the async state machine to assert
///   - timeout: the duration after which an assertion will fail if the predicate is not satisfied
///   - shouldFinishAfterAssertions: true if you want to end the state machine after the assertions flow
///   - assert: the flow of instructions to assert the behaviour of the ``AsyncStateMachine``
public func XCTAssert<SuperState, SuperEvent>(
  asyncStateMachine: AsyncStateMachine<SuperState, SuperEvent>,
  timeout: Duration? = nil,
  shouldFinishAfterAssertions: Bool = true,
  assert: (Assertions<SuperState, SuperEvent>) async -> Void
) async {
  let assertions = Assertions(
    asyncStateMachine: asyncStateMachine,
    timeout: timeout,
    shouldFinishAfterAssertions: shouldFinishAfterAssertions
  )
  await assert(assertions)
  assertions.finish()
}

/// Asserts that there is a declared transition to the expected new state
/// for a given state and event.
/// - Parameters:
///   - stateMachine: The state machine to assert
///   - state: The current state
///   - event: The received event
///   - newState: The expected new state
public func XCTAssertTransition<SuperState, SuperEvent>(
  asyncStateMachine: AsyncStateMachine<SuperState, SuperEvent>,
  when state: some State<SuperState>,
  on event: some Event<SuperEvent>,
  transitionsTo newState: some State<SuperState>,
  fail: (String, StaticString, UInt) -> Void = XCTFail(_:file:line:),
  file: StaticString = #filePath,
  line: UInt = #line
) async {
  let received = await asyncStateMachine
    .stateMachine
    .transition(state: state, event: event)?
    .transition?
    .state()

  guard let newStateReceived = received else {
    fail(
      """
      Expected state = \(state) and event = \(event) to produce new state = \(newState),
      but no new state was received.
      """,
      file,
      line
    )
    return
  }

  XCTAssertEqual(
    anyLhs: newStateReceived,
    anyRhs: newState,
    fail: fail,
    file: file,
    line: line
  )
}

/// Asserts that there is no declared transition for the state and event.
/// - Parameters:
///   - stateMachine: The state machine to assert
///   - state: The current state
///   - event: The received event
public func XCTAssertNoTransition<SuperState, SuperEvent>(
  asyncStateMachine: AsyncStateMachine<SuperState, SuperEvent>,
  when state: some State<SuperState>,
  on event: some Event<SuperEvent>,
  fail: (String, StaticString, UInt) -> Void = XCTFail(_:file:line:),
  file: StaticString = #filePath,
  line: UInt = #line
) async {
  let received = await asyncStateMachine
    .stateMachine
    .transition(state: state, event: event)?
    .transition?
    .state()

  if let newState = received {
    fail(
      """
      Expected there to be no transition, but there is a transition
      for state=\(state) and event=\(event) => new state=\(newState)
      """,
      file,
      line
    )
  }
}
#endif
