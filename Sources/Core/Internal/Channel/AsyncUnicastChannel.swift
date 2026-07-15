import DequeModule
import os

/// A single-consumer asynchronous channel with FIFO buffering.
///
/// The channel deliberately permits a new iterator after the previous iterator is
/// released or cancelled. This is needed by SwiftUI task lifecycles, where an
/// observation task may disappear while the owner of the channel remains alive.
/// It is not a multicast sequence: attempting to create two live iterators is a
/// programming error because doing so would make consumption nondeterministic.
///
/// `@unchecked Sendable` is limited to this small synchronization boundary. Every
/// mutable value, including the suspended continuation and iterator lease, is
/// accessed under `storage` and continuations are always resumed after the lock has
/// been released.
final class AsyncUnicastChannel<Element>: AsyncSequence, @unchecked Sendable where Element: Sendable {
  typealias AsyncIterator = Iterator

  private struct Storage {
    var buffered = Deque<Element>()
    var continuation: CheckedContinuation<Element?, Never>?
    var isFinished = false
    var hasIterator = false
    var onSuspended: (@Sendable () -> Void)?
  }

  private let storage = OSAllocatedUnfairLock(initialState: Storage())

  /// Package-internal test and diagnostic probe. It is intentionally
  /// configuration-independent so Release tests exercise the real lifecycle.
  var onSuspended: (@Sendable () -> Void)? {
    get { storage.withLock { $0.onSuspended } }
    set { storage.withLock { $0.onSuspended = newValue } }
  }

  @discardableResult
  func send(_ element: Element) -> Bool {
    let result = storage.withLock { state -> (accepted: Bool, continuation: CheckedContinuation<Element?, Never>?) in
      guard !state.isFinished else { return (false, nil) }
      if let continuation = state.continuation {
        state.continuation = nil
        return (true, continuation)
      }
      state.buffered.append(element)
      return (true, nil)
    }
    result.continuation?.resume(returning: element)
    return result.accepted
  }

  func finish() {
    let continuation = storage.withLock { state -> CheckedContinuation<Element?, Never>? in
      guard !state.isFinished else { return nil }
      state.isFinished = true
      defer { state.continuation = nil }
      return state.continuation
    }
    continuation?.resume(returning: nil)
  }

  func makeAsyncIterator() -> Iterator {
    let canStart = storage.withLock { state in
      guard !state.hasIterator else { return false }
      state.hasIterator = true
      return true
    }
    precondition(
      canStart,
      "AsyncUnicastChannel allows a single iterator at a time. " +
      "This is required to keep state transitions deterministic."
    )
    return Iterator(channel: self, lease: IterationLease(channel: self))
  }

  var queuedElements: any Collection<Element> {
    storage.withLock { Array($0.buffered) }
  }

  var isFinishedWithoutElements: Bool {
    storage.withLock { $0.isFinished && $0.buffered.isEmpty }
  }

  var isFinished: Bool {
    storage.withLock { $0.isFinished }
  }

  var hasActiveIterator: Bool {
    storage.withLock { $0.hasIterator }
  }

  private func next() async -> Element? {
    guard !Task.isCancelled else { return nil }

    return await withTaskCancellationHandler(operation: {
      await withCheckedContinuation { continuation in
        let action = storage.withLock { state -> NextAction in
          // The cancellation handler may have run before this continuation was
          // registered. Checking inside the same critical section closes that
          // cancellation-registration race.
          guard !Task.isCancelled else { return .resume(continuation, nil) }

          if let element = state.buffered.popFirst() {
            return .resume(continuation, element)
          }
          if state.isFinished {
            return .resume(continuation, nil)
          }

          precondition(state.continuation == nil, "Invalid channel state: multiple suspended iterators")
          state.continuation = continuation
          return .suspend(state.onSuspended)
        }

        switch action {
        case .resume(let continuation, let element):
          continuation.resume(returning: element)
        case .suspend(let callback):
          callback?()
        }
      }
    }, onCancel: { [weak self] in
      self?.cancelSuspendedIteration()
    })
  }

  private func cancelSuspendedIteration() {
    let continuation = storage.withLock { state -> CheckedContinuation<Element?, Never>? in
      defer { state.continuation = nil }
      return state.continuation
    }
    continuation?.resume(returning: nil)
  }

  private func releaseIterator() {
    cancelSuspendedIteration()
    storage.withLock { $0.hasIterator = false }
  }

  private enum NextAction {
    case resume(CheckedContinuation<Element?, Never>, Element?)
    case suspend((@Sendable () -> Void)?)
  }

  fileprivate final class IterationLease: @unchecked Sendable {
    private weak var channel: AsyncUnicastChannel?
    private let didEnd = OSAllocatedUnfairLock(initialState: false)

    init(channel: AsyncUnicastChannel) {
      self.channel = channel
    }

    deinit {
      end()
    }

    func end() {
      let shouldEnd = didEnd.withLock { value in
        guard !value else { return false }
        value = true
        return true
      }
      guard shouldEnd else { return }
      channel?.releaseIterator()
    }
  }
}

extension AsyncUnicastChannel {
  struct Iterator: AsyncIteratorProtocol {
    private let channel: AsyncUnicastChannel<Element>
    private let lease: IterationLease

    fileprivate init(channel: AsyncUnicastChannel<Element>, lease: IterationLease) {
      self.channel = channel
      self.lease = lease
    }

    mutating func next() async -> Element? {
      let element = await channel.next()
      if element == nil {
        lease.end()
      }
      return element
    }
  }
}
