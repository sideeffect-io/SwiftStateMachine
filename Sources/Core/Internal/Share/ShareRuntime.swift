import os

final class ShareRuntime<Base: AsyncSequence>: Sendable where Base: Sendable, Base.Element: Sendable {

  // MARK: - Lifecycle

  init(base: Base, replayCount: ReplayCount) {
    stateMachine = OSAllocatedUnfairLock(initialState: ShareStateMachine(base: base, replayCount: replayCount))
    idCounter = OSAllocatedUnfairLock(initialState: 0)
  }

  deinit {
    let task = self.stateMachine.withLock { $0.task }
    task?.cancel()
  }

  // MARK: - Properties

  // MARK: Private

  private let stateMachine: OSAllocatedUnfairLock<ShareStateMachine<Base>>
  private let idCounter: OSAllocatedUnfairLock<Int>

  // MARK: - Methods

  // MARK: Internal

  func generateId() -> Int {
    idCounter.withLock { ids in
      ids += 1
      return ids
    }
  }

  func next(channelId: Int, channel: AsyncUnicastChannel<Base.Element>) -> Bool {
    stateMachine.withLock { stateMachine -> Bool in
      let action = stateMachine.next(channelId: channelId, channel: channel)
      switch action {
      case .startTask(let base):
        self.startTask(stateMachine: &stateMachine, base: base)
        return true
      case .waitForChannelNextElement:
        return true
      case .finishChannel:
        channel.finish()
        return false
      case .replay(let elements):
        elements.forEach { channel.send($0) }
        return true
      case .replayAndFinish(let elements):
        elements.forEach { channel.send($0) }
        channel.finish()
        return true
      case .resumeBaseNextContinuationAndWaitForChannelNextElement(let baseContinuation):
        baseContinuation?.resume()
        return true
      }
    }
  }

  @Sendable
  func cancel(channelId: Int) {
    stateMachine.withLock { stateMachine in
      stateMachine.cancelFromChannel(channelId: channelId)
    }
  }

  private func startTask(
    stateMachine: inout ShareStateMachine<Base>,
    base: Base
  ) {
    let task = Task<Void, Never> {
      do {
        var iterator = base.makeAsyncIterator()
        baseLoop: while true {
          await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
            self.stateMachine.withLock { stateMachine in
              let action = stateMachine.baseIsSuspended(continuation: continuation)

              switch action {
              case .remainSuspended:
                break
              case .resume(let continuation):
                continuation.resume()
              }
            }
          }

          guard let element = try await iterator.next() else {
            // the base async sequence is finished
            break baseLoop
          }

          self.stateMachine.withLock { stateMachine in
            let action = stateMachine.elementFromBase(element: element)

            switch action {
            case .send(let channels, let element):
              channels.forEach { $0.send(element) }
            }
          }
        }

        self.stateMachine.withLock { stateMachine in
          let action = stateMachine.finishFromBase()

          switch action {
          case .finishChannels(let channels):
            channels.forEach { $0.finish() }
          }
        }
      } catch {
        // an async state machine sequence cannot fail, so this case CANNOT happen
        // (in a more generic case where we don't know if the base sequence can fail or not
        // we should handle the error of course)
        self.stateMachine.withLock { stateMachine in
          let action = stateMachine.finishFromBase()

          switch action {
          case .finishChannels(let channels):
            channels.forEach { $0.finish() }
          }
        }
      }
    }

    stateMachine.taskIsStarted(task: task)
  }
}
