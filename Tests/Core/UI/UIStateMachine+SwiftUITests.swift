import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class UIStateMachineSwiftUITests: XCTestCase {

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    asyncStateMachine = AsyncStateMachine<MockSuperState, MockSuperEvent>(initial: Idle()) {
      When(state: Idle.self) {
        On(event: LoadingWasRequested.self) { _, _ in
          Transition(state: TestedState.loading)
        }
      }

      When(state: Loading.self) {
        On(event: LoadingHasSucceeded.self) { _, _ in
          Transition(state: TestedState.loaded)
        }
      }
    }
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
    asyncStateMachine = nil
  }

  // MARK: - Properties

  var sut: UIStateMachine<MockSuperState, MockSuperEvent>!
  var asyncStateMachine: AsyncStateMachine<MockSuperState, MockSuperEvent>!

  // MARK: - Methods

  @MainActor
  func test_binding_withClosures_readsSubstateAndSendsEvent() {
    let uiStateMachineIsStarted = expectation(description: "The view state machine is started")
    let uiStateMachineHasReceivedLoadingHasSucceededEvent =
      expectation(description: "The view state machine has received an event to load")

    // Given
    asyncStateMachine = asyncStateMachine.onTransition { _, currentState, event, _ in
      if currentState is Idle {
        uiStateMachineIsStarted.fulfill()
      }
      if event is LoadingHasSucceeded {
        uiStateMachineHasReceivedLoadingHasSucceededEvent.fulfill()
      }
    }

    sut = UIStateMachine(asyncStateMachine: asyncStateMachine)

    let binding = sut.binding { superState in
      superState.isLoaded
    } send: { _ in
      TestedEvent.loadingSucceededWithValue1701
    }

    // When
    sut.start()

    sut.send(TestedEvent.loadingRequestedWithValue1701)

    // Then
    wait(for: [uiStateMachineIsStarted], timeout: 1.0)

    XCTAssertFalse(
      binding.wrappedValue,
      "Expected the value wrapped in the binding to be false, but got \(binding.wrappedValue) instead."
    )
    binding.wrappedValue = true

    wait(for: [uiStateMachineHasReceivedLoadingHasSucceededEvent], timeout: 1.0)
  }

  @MainActor
  func test_binding_withKeypathAndClosure_readsSubstateAndSendsEvent() {
    let uiStateMachineIsStarted = expectation(description: "The view state machine is started")
    let uiStateMachineHasReceivedLoadingHasSucceededEvent =
      expectation(description: "The view state machine has received an event to load")

    // Given
    asyncStateMachine = asyncStateMachine.onTransition { _, currentState, event, _ in
      if currentState is Idle {
        uiStateMachineIsStarted.fulfill()
      }
      if event is LoadingHasSucceeded {
        uiStateMachineHasReceivedLoadingHasSucceededEvent.fulfill()
      }
    }

    sut = UIStateMachine(asyncStateMachine: asyncStateMachine)

    let binding = sut.binding(\.isLoaded) { _ in
      TestedEvent.loadingSucceededWithValue1701
    }

    // When
    sut.start()

    sut.send(TestedEvent.loadingRequestedWithValue1701)

    // Then
    wait(for: [uiStateMachineIsStarted], timeout: 1.0)

    XCTAssertFalse(
      binding.wrappedValue,
      "Expected the value wrapped in the binding to be false, but got \(binding.wrappedValue) instead."
    )
    binding.wrappedValue = true

    wait(for: [uiStateMachineHasReceivedLoadingHasSucceededEvent], timeout: 1.0)
  }

  @MainActor
  func test_binding_withKeypathAndEvent_readsSubstateAndSendsEvent() {
    let uiStateMachineIsStarted = expectation(description: "The view state machine is started")
    let uiStateMachineHasReceivedLoadingHasSucceededEvent =
      expectation(description: "The view state machine has received an event to load")

    // Given
    asyncStateMachine = asyncStateMachine.onTransition { _, currentState, event, _ in
      if currentState is Idle {
        uiStateMachineIsStarted.fulfill()
      }
      if event is LoadingHasSucceeded {
        uiStateMachineHasReceivedLoadingHasSucceededEvent.fulfill()
      }
    }

    sut = UIStateMachine(asyncStateMachine: asyncStateMachine)

    let binding = sut.binding(\.isLoaded, send: TestedEvent.loadingSucceededWithValue1701)

    // When
    sut.start()

    sut.send(TestedEvent.loadingRequestedWithValue1701)

    // Then
    wait(for: [uiStateMachineIsStarted], timeout: 1.0)

    XCTAssertFalse(
      binding.wrappedValue,
      "Expected the value wrapped in the binding to be false, but got \(binding.wrappedValue) instead."
    )
    binding.wrappedValue = true

    wait(for: [uiStateMachineHasReceivedLoadingHasSucceededEvent], timeout: 1.0)
  }

  @MainActor
  func test_binding_withKeypath_readsSubstate() {
    let uiStateMachineIsStarted = expectation(description: "The view state machine is started")

    // Given
    asyncStateMachine = asyncStateMachine.onTransition { _, currentState, _, _ in
      if currentState is Idle {
        uiStateMachineIsStarted.fulfill()
      }
    }

    sut = UIStateMachine(asyncStateMachine: asyncStateMachine)

    let binding = sut.binding(\.isLoaded)

    // When
    sut.start()

    sut.send(TestedEvent.loadingRequestedWithValue1701)

    // Then
    wait(for: [uiStateMachineIsStarted], timeout: 1.0)

    XCTAssertFalse(
      binding.wrappedValue,
      "Expected the value wrapped in the binding to be false, but got \(binding.wrappedValue) instead."
    )
    binding.wrappedValue = true
    XCTAssertFalse(binding.wrappedValue)
  }
}
