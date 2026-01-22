// MARK: - ReplayCount

public enum ReplayCount: Sendable {
  case unbounded
  case max(count: UInt)
}

extension AsyncSequence where Self: Sendable, Self.Element: Sendable {
  /// Returns an Async Sequence that can cross task boundaries and that will
  /// broadcast the elements from the base sequence with a replay strategy.
  /// - Parameter replayCount: the amount of base elements to replay when a new task iterates over the sequence
  /// - Returns: Returns an Async Sequence that broadcasts elements from the base sequence
  public func share(replayCount: ReplayCount) -> AsyncShareSequence<Self> {
    AsyncShareSequence(base: self, replayCount: replayCount)
  }
}

// MARK: - AsyncShareSequence

public struct AsyncShareSequence<Base: AsyncSequence>: AsyncSequence, Sendable
  where Base: Sendable, Base.Element: Sendable
{
  public typealias Element = Base.Element
  public typealias AsyncIterator = Iterator

  // MARK: - Lifecycle

  init(base: Base, replayCount: ReplayCount) {
    runtime = ShareRuntime(base: base, replayCount: replayCount)
  }

  // MARK: - Properties

  // MARK: Internal

  let runtime: ShareRuntime<Base>

  // MARK: - Methods

  // MARK: Public

  public func makeAsyncIterator() -> Iterator {
    Iterator(runtime: runtime)
  }

  // MARK: - AsyncShareSequence+Iterator

  public struct Iterator: AsyncIteratorProtocol {

    // MARK: - Lifecycle

    init(runtime: ShareRuntime<Base>) {
      self.runtime = runtime
      asyncUnicastChannel = AsyncUnicastChannel()
      asyncUnicastChannelIterator = asyncUnicastChannel.makeAsyncIterator()
      id = runtime.generateId()
    }

    // MARK: - Properties

    // MARK: Internal

    let runtime: ShareRuntime<Base>
    let asyncUnicastChannel: AsyncUnicastChannel<Base.Element>
    var asyncUnicastChannelIterator: AsyncUnicastChannel<Base.Element>.AsyncIterator
    let id: Int

    // MARK: - Methods

    // MARK: Public

    public mutating func next() async -> Element? {
      guard !Task.isCancelled else {
        runtime.cancel(channelId: id)
        return nil
      }

      return await withTaskCancellationHandler {
        let shouldWaitForChannelNextElement = runtime.next(channelId: id, channel: asyncUnicastChannel)

        if shouldWaitForChannelNextElement {
          let element = await asyncUnicastChannelIterator.next()
          return element
        } else {
          return nil
        }
      } onCancel: { [runtime, id] in
        runtime.cancel(channelId: id)
      }
    }
  }
}
