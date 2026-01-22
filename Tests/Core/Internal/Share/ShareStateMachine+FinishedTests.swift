import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional

final class ShareStateMachineFinishedTests: XCTestCase {
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

  func test_whenFinishedWithReplay_andReceivingNextFromNewClientAlreadyFinished_stateIsFinished_actionIsFinishChannel() {
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]
    let newFinishedClientChannel = AsyncUnicastChannel<Int>()
    newFinishedClientChannel.finish()

    // Given state is finished
    sut.state = .finished(channels: [1: clientAsyncUnicastChannel], replay: expectedReplay)

    // When submitting next
    let action = sut.next(channelId: 2, channel: newFinishedClientChannel)

    // Then
    guard case .finished(let receivedChannels, expectedReplay) = sut.state else {
      XCTFail(
        """
        Expected the state to be .finished,
        but got \(sut.state) instead
        """
      )
      return
    }

    XCTAssertEqual(
      receivedChannels.count,
      1,
      """
      Expected to have 1 client channel,
      but got \(receivedChannels.count) instead
      """
    )

    guard case .finishChannel = action else {
      XCTFail(
        """
        Expected to receive a .finishChannel action,
        but got \(action) instead
        """
      )
      return
    }
  }

  func test_whenFinishedWithReplay_andReceivingNextFromNewClientNotFinished_stateIsFinished_actionIsReplayAndFinish() {
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]
    let newClientChannel = AsyncUnicastChannel<Int>()

    // Given state is finished
    sut.state = .finished(channels: [1: clientAsyncUnicastChannel], replay: expectedReplay)

    // When submitting next
    let action = sut.next(channelId: 2, channel: newClientChannel)

    // Then
    guard case .finished(let receivedChannels, expectedReplay) = sut.state else {
      XCTFail(
        """
        Expected the state to be .finished,
        but got \(sut.state) instead
        """
      )
      return
    }

    XCTAssertEqual(
      receivedChannels.count,
      1,
      """
      Expected to have 1 client channel,
      but got \(receivedChannels.count) instead
      """
    )

    guard case .replayAndFinish(elements: expectedReplay) = action else {
      XCTFail(
        """
        Expected to receive a replayAndFinish action with \(expectedReplay) elements,
        but got \(action) instead
        """
      )
      return
    }
  }

  func test_whenFinishedWithoutReplay_andReceivingNextFromNewClient_stateIsFinished_actionIsFinishChannel() {
    let newClientChannel = AsyncUnicastChannel<Int>()

    // Given state is finished
    sut.state = .finished(channels: [1: clientAsyncUnicastChannel], replay: [])

    // When submitting next
    let action = sut.next(channelId: 2, channel: newClientChannel)

    // Then
    guard case .finished(let receivedChannels, []) = sut.state else {
      XCTFail(
        """
        Expected the state to be .finished,
        but got \(sut.state) instead
        """
      )
      return
    }

    XCTAssertEqual(
      receivedChannels.count,
      1,
      """
      Expected to have 1 client channel,
      but got \(receivedChannels.count) instead
      """
    )

    guard case .finishChannel = action else {
      XCTFail(
        """
        Expected to receive a .finishChannel action,
        but got \(action) instead
        """
      )
      return
    }
  }

  func test_whenFinished_andReceivingNextFromExistingClientWithInternallyQueuedElements_stateIsFinished_actionIsWaitForChannelNextElement(
  ) {
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]

    clientAsyncUnicastChannel.send(1)
    clientAsyncUnicastChannel.send(2)

    // Given state is sharing
    sut.state = .finished(channels: [1: clientAsyncUnicastChannel], replay: expectedReplay)

    // When submitting next
    let action = sut.next(channelId: 1, channel: clientAsyncUnicastChannel)

    // Then
    guard case .finished(let receivedChannels, expectedReplay) = sut.state else {
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
      Expected to have 1 client channel,
      but got \(receivedChannels.count) instead
      """
    )

    guard case .waitForChannelNextElement = action else {
      XCTFail(
        """
        Expected to receive a .waitForChannelNextElement,
        but got \(action) instead
        """
      )
      return
    }
  }

  func test_whenFinished_andReceivingNextFromExistingClientWithoutInternallyQueuedElements_stateIsFinished_actionIsFinishChannel(
  ) {
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]

    // Given state is sharing
    sut.state = .finished(channels: [1: clientAsyncUnicastChannel], replay: expectedReplay)

    // When submitting next
    let action = sut.next(channelId: 1, channel: clientAsyncUnicastChannel)

    // Then
    guard case .finished(let receivedChannels, expectedReplay) = sut.state else {
      XCTFail(
        """
        Expected the state to be .sharing,
        but got \(sut.state) instead
        """
      )
      return
    }

    XCTAssertTrue(
      receivedChannels.isEmpty,
      """
      Expected to have 0 client channel,
      but got \(receivedChannels.count) instead
      """
    )

    guard case .finishChannel = action else {
      XCTFail(
        """
        Expected to receive a .finishChannel,
        but got \(action) instead
        """
      )
      return
    }
  }

  func test_whenFinished_andReceivingCancelFromChannel_stateIsFinished() {
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]

    // Given state is finished
    sut.state = .finished(channels: [1: clientAsyncUnicastChannel], replay: expectedReplay)

    // When submitting cancelFromChannel
    sut.cancelFromChannel(channelId: 1)

    // Then
    guard case .finished(let receivedChannels, expectedReplay) = sut.state else {
      XCTFail(
        """
        Expected the state to be .finished,
        but got \(sut.state) instead
        """
      )
      return
    }

    XCTAssertTrue(
      receivedChannels.isEmpty,
      """
      Expected to have 0 client channel,
      but got \(receivedChannels.count) instead
      """
    )
  }
}
