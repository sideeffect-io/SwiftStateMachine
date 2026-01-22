import StateMachineShared
import XCTest
@testable import StateMachineCore

final class LoggerTests: XCTestCase {
  func test_setLogger_setsLogFunction() async {
    let expectedTitle = "transition"
    let expectedCurrentState = Idle()
    let expectedEvent = LoadingWasRequested(id: 1701)
    let expectedNewState = Loading()

    let receivedTitle = SendableStorage<String?>(value: nil)
    let receivedCurrentState = SendableStorage<(any State)?>(value: nil)
    let receivedEvent = SendableStorage<(any Event)?>(value: nil)
    let receivedNewState = SendableStorage<(any State)?>(value: nil)

    // Given
    StateMachineCore.setLogger { title, currentState, event, newState in
      receivedTitle.set(value: title)
      receivedCurrentState.set(value: currentState)
      receivedEvent.set(value: event)
      receivedNewState.set(value: newState)
    }

    // When
    await StateMachineCore.log(
      title: expectedTitle,
      currentState: expectedCurrentState,
      event: expectedEvent,
      newState: expectedNewState,
      forceLogging: true
    )

    // Then
    receivedTitle.assertEqual(expected: expectedTitle)
    receivedCurrentState.assertEqual(expected: expectedCurrentState)
    receivedEvent.assertEqual(expected: expectedEvent)
    receivedNewState.assertEqual(expected: expectedNewState)
  }
}
