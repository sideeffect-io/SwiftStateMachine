import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class ShareStateMachineStartingBaseTaskTests: XCTestCase {
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

  func test_whenStartingBaseTask_andReceivingTaskIsStarted_stateIsSharing() {
    let expectedTask: Task<Void, Never> = Task { }

    // Given state is startingBaseTask
    sut.state = .startingBaseTask(channels: [1: clientAsyncUnicastChannel])

    // When submitting task is started
    sut.taskIsStarted(task: expectedTask)

    // Then
    guard case .sharing(expectedTask, let receivedChannels, nil, [], true) = sut.state else {
      XCTFail(
        """
        Expected the state to be .sharing,
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

  func test_whenStartingBaseTask_andReceivingNext_stateIsclientStartingBaseTask_actionIsWaitForChannelNextElement() {
    // Given state is startingBaseTask
    sut.state = .startingBaseTask(channels: [1: clientAsyncUnicastChannel])

    // When submitting next
    let action = sut.next(channelId: 2, channel: AsyncUnicastChannel<Int>())

    // Then
    guard case .startingBaseTask(let channels) = sut.state else {
      XCTFail(
        """
        Expected the state to be .startingBaseTask,
        but got \(sut.state) instead
        """
      )
      return
    }

    XCTAssertEqual(
      channels.count,
      2,
      """
      Expected to have 2 client channels,
      but got \(channels.count) instead
      """
    )

    guard case .waitForChannelNextElement = action else {
      XCTFail(
        """
        Expected to receive the action .waitForChannelNextElement,
        but got \(action) instead
        """
      )
      return
    }
  }

  func test_whenStartingBaseTask_andReceivingCancelFromChannel_stateIsclientStartingBaseTask1() {
    // Given state is startingBaseTask
    sut.state = .startingBaseTask(channels: [1: clientAsyncUnicastChannel])

    // When submitting cancelFromChannel
    sut.cancelFromChannel(channelId: 1)

    // Then
    guard case .startingBaseTask(let channels) = sut.state else {
      XCTFail(
        """
        Expected the state to be .startingBaseTask,
        but got \(sut.state) instead
        """
      )
      return
    }

    XCTAssertTrue(
      channels.isEmpty,
      """
      Expected to have 0 client channels,
      but got \(channels.count) instead
      """
    )
  }
}
