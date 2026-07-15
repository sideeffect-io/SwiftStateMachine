import Foundation
import OrderedCollections
import StateMachineCore
import StateMachineShared
import XCTestDynamicOverlay

public final class Assertions<SuperState, SuperEvent>: Sendable {
  struct Queues {
    var continuations: OrderedDictionary<UUID, UnsafeContinuation<(any State<SuperState>)?, Never>>
    var states: [any State<SuperState>]

    init() {
      continuations = [:]
      states = []
    }
  }

  // MARK: - Lifecycle

  // MARK: Internal

  init(
    asyncStateMachine: AsyncStateMachine<SuperState, SuperEvent>,
    timeout: Duration?,
    shouldFinishAfterAssertions: Bool,
    sleep: @Sendable @escaping (Duration) async -> Void = { duration in
      try? await Task.sleep(for: duration)
    }
  ) {
    send = { @Sendable (event: any Event<SuperEvent>) in asyncStateMachine.send(event: event) }
    sendAndWait = { @Sendable (event: any Event<SuperEvent>) in await asyncStateMachine.sendAndWait(event: event) }
    protectedQueues = SendableStorage(value: Queues())
    finish = {
      if shouldFinishAfterAssertions {
        asyncStateMachine.finish()
      }
    }
    self.timeout = timeout
    self.sleep = sleep
    task = Task { [protectedQueues] in
      for await state in asyncStateMachine {
        protectedQueues.apply { queues in
          if queues.continuations.isEmpty {
            // no continuation, we stack the state for a future assertion
            queues.states.append(state)
          } else {
            // an assertion is already waiting for execution, we can resume it with the current state
            queues.continuations.removeFirst().value.resume(returning: state)
          }
        }
      }
    }
  }

  deinit {
    task.cancel()
  }

  // MARK: - Properties

  // MARK: Internal

  let finish: @Sendable () -> Void

  // MARK: Private

  private let send: @Sendable (any Event<SuperEvent>) -> Void
  private let sendAndWait: @Sendable (any Event<SuperEvent>) async -> Void
  private let task: Task<Void, Never>
  private let protectedQueues: SendableStorage<Queues>
  private let timeout: Duration?
  private let sleep: @Sendable (Duration) async -> Void

  // MARK: - Methods

  // MARK: Public

  public func send(event: some Event<SuperEvent>) {
    send(event)
  }

  public func sendAndWait(event: some Event<SuperEvent>) async {
    await sendAndWait(event)
  }

  /// Asserts that the expected new state was produced
  /// - Parameters:
  ///   - state: the expected state
  ///   - fail: the fail block to execute in case of failure (default is `XCTFail`)
  ///   - file: the file path where the failure occurs (default is `#filePath`)
  ///   - line: the line where the failure occurs (default is `#line`)
  public func assert(
    state: some State<SuperState>,
    fail: (String, StaticString, UInt) -> Void = XCTFail(_:file:line:),
    file: StaticString = #filePath,
    line: UInt = #line
  ) async {
    let oldestState = await withTaskGroup(
      of: (any State<SuperState>)?.self,
      returning: (any State<SuperState>)?.self
    ) { group in

      // from now we will make 2 tasks race against each other:
      // a timeout task that returns a nil state and a task that gets the next available state
      if let timeout {
        group.addTask(operation: makeTimeoutOperation(timeout: timeout))
      }
      group.addTask(operation: makeGetOldestStateOperation())

      // we return the state from the first task to win the race
      // either it is nil because the timeout has won or it is an actual next state
      let firstReceivedState = await group.next()
      group.cancelAll()
      return firstReceivedState ?? nil
    }

    if let oldestState {
      XCTAssertEqual(
        anyLhs: state,
        anyRhs: oldestState,
        fail: fail,
        file: file,
        line: line
      )
    } else {
      fail("Timeout while asserting an equality with the state \(state)", file, line)
    }
  }

  /// Asserts that no new state was produced
  /// - Parameters:
  ///   - timeout: the timeout during which the function will suspend waiting for a potential state to be emitted.
  ///   By default `.milliseconds(250)`. It is a random value, low enough to not impact the test suite too meaningfully
  ///   - fail: the fail block to execute in case of failure (default is `XCTFail`)
  ///   - file: the file path where the failure occurs (default is `#filePath`)
  ///   - line: the line where the failure occurs (default is `#line`)
  public func assertNoTransition(
    timeout: Duration = .milliseconds(250),
    fail: (String, StaticString, UInt) -> Void = XCTFail(_:file:line:),
    file: StaticString = #filePath,
    line: UInt = #line
  ) async {
    let oldestState = await withTaskGroup(
      of: (any State<SuperState>)?.self,
      returning: (any State<SuperState>)?.self
    ) { group in

      // from now we will make 2 tasks race against each other:
      // a timeout task that returns a nil state and a task that gets the next available state
      group.addTask(operation: makeTimeoutOperation(timeout: timeout))
      group.addTask(operation: makeGetOldestStateOperation())

      // we return the state from the first task to win the race
      // either it is nil because the timeout has won or it is an actual next state
      let firstReceivedState = await group.next()
      group.cancelAll()
      return firstReceivedState ?? nil
    }

    // we expect the timeout task to win the race (a nil state is expected)
    guard oldestState == nil else {
      fail("No new state was expected but received \(String(describing: oldestState))", file, line)
      return
    }
  }

  private func makeTimeoutOperation(timeout: Duration) -> @Sendable () async -> (any State<SuperState>)? {
    { [sleep] in
      await sleep(timeout)
      return nil
    }
  }

  private func makeGetOldestStateOperation() -> @Sendable () async -> (any State<SuperState>)? {
    {
      let continuationId = UUID()
      return await withTaskCancellationHandler {
        await withUnsafeContinuation { [weak self] continuation in
          self?.protectedQueues.apply { queues in
            if queues.states.isEmpty {
              // no available state to assert against, the assertion is suspended until a new state is produced
              queues.continuations[continuationId] = continuation
            } else {
              // there is at least a state emitted by the state machine, we use the oldest one for asserting
              let oldestState = queues.states.removeFirst()
              continuation.resume(returning: oldestState)
            }
          }
        }
      } onCancel: { [weak self] in
        self?.protectedQueues.apply { queues in
          queues.continuations[continuationId]?.resume(returning: nil)
          queues.continuations[continuationId] = nil
        }
      }
    }
  }
}
