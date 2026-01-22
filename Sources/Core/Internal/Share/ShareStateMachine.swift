struct ShareStateMachine<Base: AsyncSequence>: Sendable where Base: Sendable, Base.Element: Sendable {
  // MARK: - Types

  // MARK: Internal

  enum State: Sendable {
    case initial(
      base: Base
    )
    case startingBaseTask(
      channels: [Int: AsyncUnicastChannel<Base.Element>]
    )
    case sharing(
      task: Task<Void, Never>,
      channels: [Int: AsyncUnicastChannel<Base.Element>],
      suspendedBaseContinuation: UnsafeContinuation<Void, Never>?,
      replay: [Base.Element],
      isDemand: Bool
    )
    case finished(
      channels: [Int: AsyncUnicastChannel<Base.Element>],
      replay: [Base.Element]
    )
  }

  enum NextAction {
    case startTask(base: Base)
    case waitForChannelNextElement
    case replay(elements: [Base.Element])
    case replayAndFinish(elements: [Base.Element])
    case resumeBaseNextContinuationAndWaitForChannelNextElement(continuation: UnsafeContinuation<Void, Never>?)
    case finishChannel
  }

  enum BaseIsSuspendedAction {
    case remainSuspended
    case resume(continuation: UnsafeContinuation<Void, Never>)
  }

  enum ElementFromBaseAction {
    case send(channels: any Collection<AsyncUnicastChannel<Base.Element>>, element: Base.Element)
  }

  enum FinishAction {
    case finishChannels(channels: any Collection<AsyncUnicastChannel<Base.Element>>)
  }

  // MARK: - Lifecycle

  init(base: Base, replayCount: ReplayCount) {
    state = .initial(base: base)
    self.replayCount = replayCount
  }

  // MARK: - Properties

  // MARK: Internal

  var state: State

  var task: Task<Void, Never>? {
    switch state {
    case .sharing(let task, _, _, _, _):
      task
    default:
      nil
    }
  }

  // MARK: Private

  private let replayCount: ReplayCount

  // MARK: - Methods

  // MARK: Internal

  // swiftlint:disable next cyclomatic_complexity function_body_length
  mutating func next(channelId: Int, channel: AsyncUnicastChannel<Base.Element>) -> NextAction {
    switch state {
    case .initial(let base):
      // initial client, starting the base task and queueing the first client waiting for elements
      state = .startingBaseTask(channels: [channelId: channel])
      return .startTask(base: base)

    case .startingBaseTask(var channels):
      // base task is starting, queueing the new client waiting for elements
      channels[channelId] = channel
      state = .startingBaseTask(channels: channels)
      return .waitForChannelNextElement

    // SHARING WITH A NEW CLIENT
    case .sharing(let task, var channels, let suspendedBaseContinuation, let replay, let isDemand)
      where channels[channelId] == nil && !replay.isEmpty:
      // base task is running, the client is new and will be registered, and given some elements to replay
      channels[channelId] = channel
      state = .sharing(
        task: task,
        channels: channels,
        suspendedBaseContinuation: suspendedBaseContinuation,
        replay: replay,
        isDemand: isDemand
      )
      return .replay(elements: replay)

    case .sharing(let task, var channels, let suspendedBaseContinuation, let replay, _)
      where channels[channelId] == nil && replay.isEmpty && suspendedBaseContinuation == nil:
      // base task is running, the client is new and will be registered, but no elements is to be replayed
      // we specify that there is awaiting demand to be fulfilled by the base task when it will get its next element
      channels[channelId] = channel
      state = .sharing(task: task, channels: channels, suspendedBaseContinuation: nil, replay: [], isDemand: true)
      return .waitForChannelNextElement

    case .sharing(let task, var channels, let suspendedBaseContinuation, let replay, _)
      where channels[channelId] == nil && replay.isEmpty && suspendedBaseContinuation != nil:
      // base task is running, the client is new and will be registered, but no elements is to be replayed
      // the base task is suspended, we ask to resume it so a next element can be requested
      channels[channelId] = channel
      state = .sharing(task: task, channels: channels, suspendedBaseContinuation: nil, replay: [], isDemand: false)
      return .resumeBaseNextContinuationAndWaitForChannelNextElement(continuation: suspendedBaseContinuation)

    // SHARING WITH AN EXISTING CLIENT
    case .sharing(let task, let channels, let suspendedBaseContinuation, let replay, let isDemand)
      where channels[channelId] != nil && !channel.queuedElements.isEmpty:
      // base task is running, this is a known client for which values are already stacked internally and must be consumed
      state = .sharing(
        task: task,
        channels: channels,
        suspendedBaseContinuation: suspendedBaseContinuation,
        replay: replay,
        isDemand: isDemand
      )
      return .waitForChannelNextElement

    case .sharing(let task, let channels, let suspendedBaseContinuation, let replay, _)
      where channels[channelId] != nil && channel.queuedElements.isEmpty && suspendedBaseContinuation == nil:
      // base task is running, this is a known client for which we have no elements to provide
      // we specify that there is awaiting demand to be fulfilled by the base task when it will get its next element
      state = .sharing(task: task, channels: channels, suspendedBaseContinuation: nil, replay: replay, isDemand: true)
      return .waitForChannelNextElement

    case .sharing(let task, let channels, let suspendedBaseContinuation, let replay, _)
      where channels[channelId] != nil && channel.queuedElements.isEmpty && suspendedBaseContinuation != nil:
      // base task is running, this is a known client for which we have no elements to provide
      // the base task is suspended, we ask to resume it so a next element can be requested
      state = .sharing(
        task: task,
        channels: channels,
        suspendedBaseContinuation: nil,
        replay: replay,
        isDemand: false
      )
      return .resumeBaseNextContinuationAndWaitForChannelNextElement(continuation: suspendedBaseContinuation)

    // FINISHED WITH A NEW CLIENT
    case .finished(let channels, let replay)
      where channels[channelId] == nil && !replay.isEmpty:
      // base task is finished and this is a new client that won't be registed but is given some elements to replay
      if channel.isFinishedWithoutElements {
        return .finishChannel
      }
      return .replayAndFinish(elements: replay)

    case .finished(let channels, let replay)
      where channels[channelId] == nil && replay.isEmpty:
      // base task is finished and this is a new client that won't be registed and can finish right away
      return .finishChannel

    // FINISHED WITH AN EXISTING CLIENT
    case .finished(let channels, _)
      where channels[channelId] != nil && !channel.queuedElements.isEmpty:
      // base task is finished and this is a known client that still has some elements already stacked to consume
      return .waitForChannelNextElement

    case .finished(var channels, let replay)
      where channels[channelId] != nil && channel.queuedElements.isEmpty:
      // base task is finished and this is a known client that will be unregistered and asked to finish
      channels[channelId] = nil
      state = .finished(channels: channels, replay: replay)
      return .finishChannel

    default:
      preconditionFailure("Invalid state")
    }
  }

  mutating func taskIsStarted(task: Task<Void, Never>) {
    switch state {
    case .startingBaseTask(let channels):
      // a client was necessarily waiting for an element since the task was started, that is why we set isDemand to true
      // so that the base task can directly skip to suspension point to request its next element
      state = .sharing(task: task, channels: channels, suspendedBaseContinuation: nil, replay: [], isDemand: true)

    default:
      preconditionFailure("Invalid state")
    }
  }

  mutating func baseIsSuspended(continuation: UnsafeContinuation<Void, Never>) -> BaseIsSuspendedAction {
    switch state {
    case .sharing(let task, let channels, nil, let replay, true):
      // the base task is entering a new iteration of its loop, and there is demand we must satisfy it
      // by resuming the suspension and requesting the next element of the base
      state = .sharing(
        task: task,
        channels: channels,
        suspendedBaseContinuation: nil,
        replay: replay,
        isDemand: false
      )
      return .resume(continuation: continuation)

    case .sharing(let task, let channels, nil, let replay, false):
      // the base task is entering a new iteration of its loop, and there is no demand
      // we register the continuation and remain suspended until a call to next is done vy one of the channels
      state = .sharing(
        task: task,
        channels: channels,
        suspendedBaseContinuation: continuation,
        replay: replay,
        isDemand: false
      )
      return .remainSuspended

    default:
      preconditionFailure("Invalid state")
    }
  }

  mutating func elementFromBase(element: Base.Element) -> ElementFromBaseAction {
    switch state {
    case .sharing(let task, let channels, nil, var replay, let isDemand):
      // base as produced a new element, we register it (if needed) in the replayable values
      // and ask the channels to internally send this value
      switch replayCount {
      case .unbounded:
        replay.append(element)
      case .max(0):
        break
      case .max(let count):
        if replay.count >= count {
          replay.removeFirst()
        }
        replay.append(element)
      }

      state = .sharing(
        task: task,
        channels: channels,
        suspendedBaseContinuation: nil,
        replay: replay,
        isDemand: isDemand
      )
      return .send(channels: channels.values, element: element)

    default:
      preconditionFailure("Invalid state")
    }
  }

  mutating func finishFromBase() -> FinishAction {
    switch state {
    case .sharing(_, var channels, nil, let replay, _):
      let channelsToFinish = channels.values
      for (channelId, channel) in channels {
        if channel.queuedElements.isEmpty {
          channels[channelId] = nil
        }
      }
      state = .finished(channels: channels, replay: replay)
      return .finishChannels(channels: channelsToFinish)

    default:
      preconditionFailure("Invalid state")
    }
  }

  mutating func cancelFromChannel(channelId: Int) {
    switch state {
    case .startingBaseTask(var channels):
      channels[channelId] = nil
      state = .startingBaseTask(channels: channels)

    case .sharing(let task, var channels, let suspendedBaseContinuation, let replay, let isDemand):
      channels[channelId] = nil
      state = .sharing(
        task: task,
        channels: channels,
        suspendedBaseContinuation: suspendedBaseContinuation,
        replay: replay,
        isDemand: isDemand
      )

    case .finished(var channels, let replay):
      channels[channelId] = nil
      state = .finished(channels: channels, replay: replay)

    default:
      preconditionFailure("Invalid state")
    }
  }
}
