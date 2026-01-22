import SwiftUI
import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class StateMachineViewTests: XCTestCase {

  // MARK: - Lifecycle

  override func tearDown() {
    super.tearDown()

    sut = nil
  }

  // MARK: - Properties

  var sut: (any View)!

  let asyncStateMachine = AsyncStateMachineFactory<MockSuperState, MockSuperEvent>.default(initial: Idle())

  // MARK: - Methods

  @MainActor
  func test_init_providesAsyncStateMachineToContent() {
    var received: MockSuperState?
    let expected = Idle().superState

    // Given
    sut = StateMachineView(factory: asyncStateMachine) { uiStateMachine in
      received = uiStateMachine.state
      return Text("")
    }

    // When
    _ = sut.body

    // Then
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the UIStateMachine's state in the SUT's ViewBuilder to rely on the SUT's AsyncStateMachine's state,
      but expected state was \(expected), and got \(String(describing: received)) instead.
      """
    )
  }

  @MainActor
  func test_init_whenMappingProvided_providesAsyncStateMachineToContent() {
    var received: MockUIState?
    let expected = MockUIState(isLoading: true)

    // Given
    sut = StateMachineView(factory: asyncStateMachine, mapping: { _ in
      MockUIState(isLoading: true)
    }) { uiStateMachine in
      received = uiStateMachine.state
      return Text(verbatim: "")
    }

    // When
    _ = sut.body

    // Then
    XCTAssertEqual(
      received,
      expected,
      """
      Expected the UIStateMachine's state in the SUT's ViewBuilder to rely on the SUT's AsyncStateMachine's state,
      but expected state was \(expected), and got \(String(describing: received)) instead.
      """
    )
  }
}
