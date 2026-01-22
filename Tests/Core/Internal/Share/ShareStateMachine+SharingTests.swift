import XCTest
@testable import StateMachineCore

// swiftlint:disable implicitly_unwrapped_optional file_length function_body_length type_body_length

final class ShareStateMachineSharingTests: XCTestCase {
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

  func test_whenSharingWithReplay_andReceivingNextFromNewClient_stateIsSharing_actionIsReplay() {
    let expectedTask: Task<Void, Never> = Task { }
    let expectedDemand = Bool.random()
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]

    // Given state is sharing
    sut.state = .sharing(
      task: expectedTask,
      channels: [1: clientAsyncUnicastChannel],
      suspendedBaseContinuation: nil,
      replay: expectedReplay,
      isDemand: expectedDemand
    )

    // When submitting next
    let action = sut.next(channelId: 2, channel: AsyncUnicastChannel<Int>())

    // Then
    guard case .sharing(expectedTask, let receivedChannels, nil, expectedReplay, expectedDemand) = sut.state else {
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
      2,
      """
      Expected to have 2 client channels,
      but got \(receivedChannels.count) instead
      """
    )

    guard case .replay(elements: expectedReplay) = action else {
      XCTFail(
        """
        Expected to receive a replay action with \(expectedReplay) elements,
        but got \(action) instead
        """
      )
      return
    }
  }

  func test_whenSharingWithoutReplay_andReceivingNextFromNewClient_stateIsSharing_actionIsWaitForChannelNextElement() {
    let expectedTask: Task<Void, Never> = Task { }
    let demand = Bool.random()

    // Given state is sharing
    sut.state = .sharing(
      task: expectedTask,
      channels: [1: clientAsyncUnicastChannel],
      suspendedBaseContinuation: nil,
      replay: [],
      isDemand: demand
    )

    // When submitting next
    let action = sut.next(channelId: 2, channel: AsyncUnicastChannel<Int>())

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
      2,
      """
      Expected to have 2 client channels,
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

  func test_whenSharingWithoutReplayAndSuspendedContinuation_andReceivingNextFromNewClient_stateIsSharing_actionIsResumeBaseNextContinuationAndWaitForChannelNextElement(
  ) async {
    let expectedTask: Task<Void, Never> = Task { }
    let demand = Bool.random()

    await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
      // Given state is sharing
      sut.state = .sharing(
        task: expectedTask,
        channels: [1: clientAsyncUnicastChannel],
        suspendedBaseContinuation: continuation,
        replay: [],
        isDemand: demand
      )

      // When submitting next
      let action = sut.next(channelId: 2, channel: AsyncUnicastChannel<Int>())

      // Then
      guard case .sharing(expectedTask, let receivedChannels, let newContinuation, [], false) = sut.state else {
        XCTFail(
          """
          Expected the state to be .sharing,
          but got \(sut.state) instead
          """
        )
        continuation.resume()
        return
      }

      XCTAssertEqual(
        receivedChannels.count,
        2,
        """
        Expected to have 2 client channels,
        but got \(receivedChannels.count) instead
        """
      )

      XCTAssertNil(
        newContinuation,
        """
        Expected the base continuation to be nil,
        but got \(String(describing: newContinuation)) instead
        """
      )

      guard
        case .resumeBaseNextContinuationAndWaitForChannelNextElement(continuation: let receivedContinuation) =
        action else
      {
        XCTFail(
          """
          Expected to receive a .resumeBaseNextContinuationAndWaitForChannelNextElement,
          but got \(action) instead
          """
        )
        continuation.resume()
        return
      }

      XCTAssertNotNil(
        receivedContinuation,
        """
        Expected to receive a non nil continuation to resume,
        but got nil instead
        """
      )

      receivedContinuation!.resume()
    }
  }

  func test_whenSharing_andReceivingNextFromExistingClientWithInternallyQueuedElements_stateIsSharing_actionIswaitForChannelNextElement(
  ) {
    let expectedTask: Task<Void, Never> = Task { }
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]
    let expectedDemand = Bool.random()

    clientAsyncUnicastChannel.send(1)
    clientAsyncUnicastChannel.send(2)

    // Given state is sharing
    sut.state = .sharing(
      task: expectedTask,
      channels: [1: clientAsyncUnicastChannel],
      suspendedBaseContinuation: nil,
      replay: expectedReplay,
      isDemand: expectedDemand
    )

    // When submitting next
    let action = sut.next(channelId: 1, channel: clientAsyncUnicastChannel)

    // Then
    guard case .sharing(expectedTask, let receivedChannels, _, expectedReplay, expectedDemand) = sut.state else {
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

  func test_whenSharingWithNilContinuation_andReceivingNextFromExistingClientWithoutInternallyQueuedElements_stateIsSharing_actionIswaitForChannelNextElement(
  ) {
    let expectedTask: Task<Void, Never> = Task { }
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]
    let expectedDemand = Bool.random()

    // Given state is sharing
    sut.state = .sharing(
      task: expectedTask,
      channels: [1: clientAsyncUnicastChannel],
      suspendedBaseContinuation: nil,
      replay: expectedReplay,
      isDemand: expectedDemand
    )

    // When submitting next
    let action = sut.next(channelId: 1, channel: clientAsyncUnicastChannel)

    // Then
    guard case .sharing(expectedTask, let receivedChannels, nil, expectedReplay, true) = sut.state else {
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

  func test_whenSharingSuspendedContinuation_andReceivingNextFromExistingClientWithoutInternallyQueuedElements_stateIsSharing_actionIsResumeBaseNextContinuationAndWaitForChannelNextElement(
  ) async {
    let expectedTask: Task<Void, Never> = Task { }
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]
    let demand = Bool.random()

    await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
      // Given state is sharing
      sut.state = .sharing(
        task: expectedTask,
        channels: [1: clientAsyncUnicastChannel],
        suspendedBaseContinuation: continuation,
        replay: expectedReplay,
        isDemand: demand
      )

      // When submitting next
      let action = sut.next(channelId: 1, channel: clientAsyncUnicastChannel)

      // Then
      guard
        case .sharing(
          expectedTask,
          let receivedChannels,
          let newContinuation,
          expectedReplay,
          false
        ) = sut.state else
      {
        XCTFail(
          """
          Expected the state to be .sharing,
          but got \(sut.state) instead
          """
        )
        continuation.resume()
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

      XCTAssertNil(
        newContinuation,
        """
        Expected the base continuation to be nil,
        but got \(String(describing: newContinuation)) instead
        """
      )

      guard
        case .resumeBaseNextContinuationAndWaitForChannelNextElement(continuation: let receivedContinuation) =
        action else
      {
        XCTFail(
          """
          Expected to receive a .resumeBaseNextContinuationAndWaitForChannelNextElement,
          but got \(action) instead
          """
        )
        continuation.resume()
        return
      }

      XCTAssertNotNil(
        receivedContinuation,
        """
        Expected to receive a non nil continuation to resume,
        but got nil instead
        """
      )

      receivedContinuation!.resume()
    }
  }

  func test_whenSharingWithDemand_andBaseIsSuspended_stateIsSharing_actionIsResume() async {
    let expectedTask: Task<Void, Never> = Task { }
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]

    // Given state is sharing
    sut.state = .sharing(
      task: expectedTask,
      channels: [1: clientAsyncUnicastChannel],
      suspendedBaseContinuation: nil,
      replay: expectedReplay,
      isDemand: true
    )

    await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
      // When submitting baseIsSuspended
      let action = sut.baseIsSuspended(continuation: continuation)

      // Then
      guard
        case .sharing(
          expectedTask,
          let receivedChannels,
          nil,
          expectedReplay,
          false
        ) = sut.state else
      {
        XCTFail(
          """
          Expected the state to be .sharing,
          but got \(sut.state) instead
          """
        )
        continuation.resume()
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

      guard case .resume(let receivedContinuation) = action else {
        XCTFail(
          """
          Expected to receive a .remainSuspended,
          but got \(action) instead
          """
        )
        continuation.resume()
        return
      }

      receivedContinuation.resume()
    }
  }

  func test_whenSharingWithoutDemand_andBaseIsSuspended_stateIsSharing_actionIsRemainSuspended() async {
    let expectedTask: Task<Void, Never> = Task { }
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]

    // Given state is sharing
    sut.state = .sharing(
      task: expectedTask,
      channels: [1: clientAsyncUnicastChannel],
      suspendedBaseContinuation: nil,
      replay: expectedReplay,
      isDemand: false
    )

    await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
      // When submitting baseIsSuspended
      let action = sut.baseIsSuspended(continuation: continuation)

      // Then
      guard
        case .sharing(
          expectedTask,
          let receivedChannels,
          let receivedContinuation,
          expectedReplay,
          false
        ) = sut.state else
      {
        XCTFail(
          """
          Expected the state to be .sharing,
          but got \(sut.state) instead
          """
        )
        continuation.resume()
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

      guard case .remainSuspended = action else {
        XCTFail(
          """
          Expected to receive a .remainSuspended,
          but got \(action) instead
          """
        )
        continuation.resume()
        return
      }

      XCTAssertNotNil(
        receivedContinuation,
        """
        Expected to receive a non nil continuation to resume,
        but got nil instead
        """
      )

      receivedContinuation!.resume()
    }
  }

  func test_whenSharing_andReceivingElementFromBase_stateIsSharing_actionIsSend_replayIsUpdated() async {
    let expectedElement = Int.random(in: 1...1000)
    let expectedTask: Task<Void, Never> = Task { }
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]
    let expectedNewReplay = expectedReplay + [expectedElement]
    let expectedDemand = Bool.random()

    // Given state is sharing
    sut.state = .sharing(
      task: expectedTask,
      channels: [1: clientAsyncUnicastChannel],
      suspendedBaseContinuation: nil,
      replay: expectedReplay,
      isDemand: expectedDemand
    )

    // When submitting elementFromBase
    let action = sut.elementFromBase(element: expectedElement)

    // Then
    guard
      case .sharing(
        expectedTask,
        let receivedChannels,
        nil,
        expectedNewReplay,
        expectedDemand
      ) = sut.state else
    {
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

    guard case .send(let receivedChannelsForSending, expectedElement) = action else {
      XCTFail(
        """
        Expected to receive a .resumeBaseNextContinuationAndWaitForChannelNextElement,
        but got \(action) instead
        """
      )
      return
    }

    XCTAssertEqual(
      receivedChannelsForSending.count,
      1,
      """
      Expected to have 1 client channel for sending,
      but got \(receivedChannelsForSending.count) instead
      """
    )
  }

  func test_whenSharing_andReceivingFinishFromBase_stateIsFinished_actionIsFinishChannels() async {
    let expectedTask: Task<Void, Never> = Task { }
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]
    let demand = Bool.random()

    // Given state is sharing
    sut.state = .sharing(
      task: expectedTask,
      channels: [1: clientAsyncUnicastChannel],
      suspendedBaseContinuation: nil,
      replay: expectedReplay,
      isDemand: demand
    )

    // When submitting finishFromBase
    let action = sut.finishFromBase()

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

    guard case .finishChannels(let receivedChannelsForFinishing) = action else {
      XCTFail(
        """
        Expected to receive a .resumeBaseNextContinuationAndWaitForChannelNextElement,
        but got \(action) instead
        """
      )
      return
    }

    XCTAssertEqual(
      receivedChannelsForFinishing.count,
      1,
      """
      Expected to have 1 client channel for finishing,
      but got \(receivedChannelsForFinishing.count) instead
      """
    )
  }

  func test_whenSharing_andReceivingCancelFromBase_stateIsSharing() async {
    let expectedTask: Task<Void, Never> = Task { }
    let expectedReplay = [Int.random(in: 1...1000), Int.random(in: 1...1000)]
    let expectedDemand = Bool.random()

    // Given state is sharing
    sut.state = .sharing(
      task: expectedTask,
      channels: [1: clientAsyncUnicastChannel],
      suspendedBaseContinuation: nil,
      replay: expectedReplay,
      isDemand: expectedDemand
    )

    // When submitting cancelFromChannel
    sut.cancelFromChannel(channelId: 1)

    // Then
    guard
      case .sharing(
        expectedTask,
        let receivedChannels,
        nil,
        expectedReplay,
        expectedDemand
      ) = sut.state else
    {
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
  }
}
