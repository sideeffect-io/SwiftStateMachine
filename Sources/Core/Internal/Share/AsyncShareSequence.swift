// MARK: - ReplayCount

public enum ReplayCount: Sendable {
  case unbounded
  case max(count: UInt)
}

extension AsyncSequence where Self: Sendable, Self.Element: Sendable {
  /// Shares one base iteration between independent clients. The historical
  /// non-throwing behavior is retained: a failing base simply finishes the
  /// shared sequence.
  public func share(replayCount: ReplayCount) -> AsyncShareSequence<Self> {
    AsyncShareSequence(base: self, replayCount: replayCount)
  }
}

public struct AsyncShareSequence<Base: AsyncSequence>: AsyncSequence, Sendable
  where Base: Sendable, Base.Element: Sendable
{
  public typealias Element = Base.Element
  public typealias AsyncIterator = Iterator

  init(base: Base, replayCount: ReplayCount) {
    runtime = ShareRuntime(base: base, replayCount: replayCount)
  }

  let runtime: ShareRuntime<Base>

  public func makeAsyncIterator() -> Iterator {
    let client = runtime.makeClient()
    return Iterator(
      runtime: runtime,
      channel: client.channel,
      lease: client.lease,
      id: client.id
    )
  }

  public struct Iterator: AsyncIteratorProtocol {
    private let runtime: ShareRuntime<Base>
    private let channel: AsyncUnicastChannel<Base.Element>
    private let lease: ShareRuntime<Base>.ClientLease
    private var channelIterator: AsyncUnicastChannel<Base.Element>.Iterator
    private let id: Int
    private var hasRegistered = false

    fileprivate init(
      runtime: ShareRuntime<Base>,
      channel: AsyncUnicastChannel<Base.Element>,
      lease: ShareRuntime<Base>.ClientLease,
      id: Int
    ) {
      self.runtime = runtime
      self.channel = channel
      self.lease = lease
      channelIterator = channel.makeAsyncIterator()
      self.id = id
    }

    public mutating func next() async -> Element? {
      guard !Task.isCancelled else {
        lease.end()
        return nil
      }

      return await withTaskCancellationHandler(operation: {
        if !hasRegistered {
          hasRegistered = true
          guard runtime.request(clientID: id, channel: channel, lease: lease) else {
            return nil
          }
        }
        let element = await channelIterator.next()
        if element == nil {
          lease.end()
        }
        return element
      }, onCancel: { [lease] in
        lease.end()
      })
    }
  }
}
