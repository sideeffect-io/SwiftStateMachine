import os
import StateMachineShared
import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional function_body_length

final class AsyncStateMachineFactoryTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: AsyncStateMachineFactory<MockSuperState, MockSuperEvent>!

  // MARK: - Methods

  func test_init_whenInstanceLifecycle_returnsNewInstanceForEachCall() {
    let calls = OSAllocatedUnfairLock(initialState: 0)
    let expectedCalls = 2

    // Given
    sut = AsyncStateMachineFactory<MockSuperState, MockSuperEvent>(lifecycle: .instance) {
      calls.withLock { $0 += 1 }
      return AsyncStateMachine(initial: Idle()) { }
    }

    // When
    let (asyncStateMachine1, _) = sut.build()
    let (asyncStateMachine2, _) = sut.build()

    // Then
    let receivedCalls = calls.withLock { $0 }
    XCTAssertEqual(
      receivedCalls,
      expectedCalls,
      """
      Expected the build function to be called \(expectedCalls) time(s),
      But got called \(receivedCalls) instead.
      """
    )

    XCTAssertTrue(
      asyncStateMachine1 !== asyncStateMachine2,
      """
      Expected the build function to return different async state machine instances,
      But got the same reference twice
      """
    )
  }

  func test_init_whenSingletonLifecycle_returnsSameInstanceForEachCall() {
    let calls = OSAllocatedUnfairLock(initialState: 0)
    let expectedCalls = 1

    // Given
    sut = AsyncStateMachineFactory<MockSuperState, MockSuperEvent>(lifecycle: .singleton) {
      calls.withLock { $0 += 1 }
      return AsyncStateMachine(initial: Idle()) { }
    }

    // When
    let (asyncStateMachine1, _) = sut.build()
    let (asyncStateMachine2, _) = sut.build()

    // Then
    let receivedCalls = calls.withLock { $0 }
    XCTAssertEqual(
      receivedCalls,
      expectedCalls,
      """
      Expected the build function to be called \(expectedCalls) time(s),
      But got called \(receivedCalls) instead.
      """
    )

    XCTAssertTrue(
      asyncStateMachine1 === asyncStateMachine2,
      """
      Expected the build function to return the same async state machine instance,
      But got different references instead
      """
    )
  }

  func test_init_whenSingletonLifecycle_returnsSharedAsyncStateMachine_andReplaysLastState() async {
    let expectedInitialState = Idle()
    let expectedLoadingState = Loading()

    // Given
    sut = AsyncStateMachineFactory<MockSuperState, MockSuperEvent>(lifecycle: .singleton) {
      AsyncStateMachine(initial: expectedInitialState) {
        When(state: Idle.self) {
          On(event: LoadingWasRequested.self) { _, _ in
            Transition(state: expectedLoadingState)
          }
        }
      }
    }

    // When
    let (asyncStateMachine, sharedStateMachine) = sut.build()
    asyncStateMachine.send(event: LoadingWasRequested(id: 1))
    asyncStateMachine.finish()

    var received1 = [any State<MockSuperState>]()
    for await element in sharedStateMachine {
      received1.append(element)
    }

    var received2 = [any State<MockSuperState>]()
    for await element in sharedStateMachine {
      received2.append(element)
    }

    // Then
    XCTAssertEqual(
      received1.count,
      2,
      """
      Expected the first iteration to have received 2 states
      """
    )

    XCTAssertEqual(
      received2.count,
      1,
      """
      Expected the second iteration to have received only the last known state
      """
    )

    XCTAssertEqual(
      anyLhs: received1[0],
      anyRhs: expectedInitialState
    )

    XCTAssertEqual(
      anyLhs: received1[1],
      anyRhs: expectedLoadingState
    )

    XCTAssertEqual(
      anyLhs: received2[0],
      anyRhs: expectedLoadingState
    )
  }

  func test_default_setsTheStateMachinesInitialState() {
    let expected = Idle()

    // Given
    sut = AsyncStateMachineFactory<MockSuperState, MockSuperEvent>.default(initial: expected)

    // When
    let (asyncStateMachine, _) = sut.build()

    // Then
    let received = asyncStateMachine.stateMachine.initial
    XCTAssertEqual(anyLhs: received, anyRhs: expected)
  }
}
