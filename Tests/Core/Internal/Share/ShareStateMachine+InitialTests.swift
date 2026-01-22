import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class ShareStateMachineInitialTests: XCTestCase {
  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()

    clientAsyncUnicastChannel = AsyncUnicastChannel()
    sut = ShareStateMachine<AsyncUnicastChannel<Int>>(base: clientAsyncUnicastChannel, replayCount: .unbounded)
  }

  override func tearDown() {
    super.tearDown()

    sut = nil
    clientAsyncUnicastChannel = nil
  }

  // MARK: - Properties

  var clientAsyncUnicastChannel: AsyncUnicastChannel<Int>!
  var sut: ShareStateMachine<AsyncUnicastChannel<Int>>!

  func test_whenInitial_and_receivingNext_stateIsStartingBaseTask_actionIsStartTask() {
    // Given initial state

    // When submitting a next event
    let action = sut.next(channelId: 1, channel: clientAsyncUnicastChannel)

    // Then
    guard case .startTask = action else {
      XCTFail(
        """
        Expected the action to be .startTask,
        but got \(action) instead
        """
      )
      return
    }

    guard case .startingBaseTask(let receivedChannels) = sut.state else {
      XCTFail(
        """
        Expected the state to be .startingBaseTask,
        but got \(sut.state) instead
        """
      )
      return
    }

    XCTAssertEqual(
      receivedChannels.count,
      1,
      """
      Expected to have a single client channel,
      but got \(receivedChannels.count) instead
      """
    )
  }
}
