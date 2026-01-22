import StateMachineCore
import StateMachineTest
import XCTest
@testable import Clics

// MARK: - MockError

struct MockError: Error { }

// MARK: - StateMachineTests

// swiftlint:disable implicitly_unwrapped_optional

final class StateMachineTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Types

  private enum TestedState {
    static let idle = DataIsIdle()
    static let loading = DataIsLoading()
    static let loadedNumberOfLoadsOne = DataIsLoaded(numberOfLoads: 1)
    static let loadedNumberOfLoadTwo = DataIsLoaded(numberOfLoads: 2)
  }

  private enum TestedEvent {
    static let loadingRequested = DidRequestLoading()
    static let resetRequested = DidRequestReset()
  }

  private enum TestedOutput {
    static let nonThrowingOutput = LoadOutput { }
    static let throwingOutput = LoadOutput { throw MockError() }
  }

  // MARK: - Properties

  var sut: AsyncStateMachine<ClicsState, ClicsEvent>!

  // MARK: - Methods

  func test_send_eventTriggeringThrowingOutput_transitionsToExpectedState() async {
    // Given
    sut = makeContinuingStateMachine(initial: TestedState.idle, load: TestedOutput.throwingOutput)

    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      // When / Then
      await assertions.assert(state: TestedState.idle)

      // When
      assertions.send(event: TestedEvent.loadingRequested)
      // Then
      await assertions.assert(state: TestedState.loading)

      // When
      assertions.send(event: TestedEvent.loadingRequested)
      // Then
      await assertions.assert(state: TestedState.loading)
    }
  }

  func test_send_eventTriggeringNonThrowingOutput_transitionsToExpectedState() async {
    // Given
    sut = makeContinuingStateMachine(initial: TestedState.idle, load: TestedOutput.nonThrowingOutput)

    await XCTAssert(asyncStateMachine: sut, timeout: .milliseconds(500)) { assertions in
      // When / Then
      await assertions.assert(state: TestedState.idle)

      // When
      assertions.send(event: TestedEvent.loadingRequested)
      // Then
      await assertions.assert(state: TestedState.loading)
      await assertions.assert(state: TestedState.loadedNumberOfLoadsOne)

      // When
      assertions.send(event: TestedEvent.loadingRequested)
      // Then
      await assertions.assert(state: TestedState.loadedNumberOfLoadTwo)

      // When
      assertions.send(event: TestedEvent.resetRequested)
      // Then
      await assertions.assert(state: TestedState.idle)
    }
  }
}
