import os
import StateMachineShared

/// An ``AsyncUnicastChannel`` is a type that aims to allow communication between the sync world and a Task under the shape
/// of an ``AsyncSequence``. It is more or less the equivalent to a Subject in the Combine world.
/// Elements can be sent to the channel with the `send(_:)` function.
/// Those elements can be consumed by an iterator of the ``AsyncSequence``. It is close to the definition of an ``AsyncStream``, but
/// ``AsyncStream`` does not allow an iterator to be cancelled and then a second one to iterate again.
/// (and we need that because in the context of a `.task {}` modifier in a SwiftUI view, an ``AsyncStateMachine`` might be cancelled - when
/// the when is removed from the hierarchy - and then the very same ``AsyncStateMachine`` will be reused if the view is displayed again -
/// typically in a list/detail -).
/// As this is a unicast channel, only ONE iterator is allowed, which fits our needs since we use it in the ``AsyncStateMachine`` to consume
/// the events given to the state machine, and ``AsyncStateMachine`` should have only ONE iterator so it can be deterministic
/// (concurrent transition wise).
/// @unchecked Sendable is justified by internal locking and the single-iterator invariant.
/// This type is safe to share across tasks as long as only one iterator is active at a time.
/// TODO: Replace with a Sendable primitive or actor-based design to remove @unchecked.
final class AsyncUnicastChannel<Element>: AsyncSequence, @unchecked Sendable where Element: Sendable {
  // MARK: - Lifecycle

  // MARK: Internal

  init() {
    stateMachine = SendableStorage(value: UnicastChannelStateMachine())
    isIteratingStorage = OSAllocatedUnfairLock(initialState: false)
  }

  // MARK: - Typealiases

  // MARK: Internal

  typealias Element = Element
  typealias AsyncIterator = Iterator

  // MARK: - Properties

  // MARK: Internal

  let stateMachine: SendableStorage<UnicastChannelStateMachine<Element>>
  let isIteratingStorage: OSAllocatedUnfairLock<Bool>

  #if DEBUG
  var onSuspended: (@Sendable () -> Void)?
  #endif

  // MARK: - Methods

  // MARK: Internal

  func send(_ element: Element) {
    stateMachine.apply { stateMachine in
      let action = stateMachine.newElement(element)

      switch action {
      case .none:
        break
      case .resumeDownstream(let continuation):
        continuation.resume(returning: element)
      }
    }
  }

  func finish() {
    stateMachine.apply { stateMachine in
      let action = stateMachine.finish()

      switch action {
      case .none:
        break
      case .resumeDownstream(let continuation):
        continuation.resume(returning: nil)
      }
    }
  }

  func makeAsyncIterator() -> Iterator {
    let canStart = isIteratingStorage.withLock { isIterating in
      guard !isIterating else { return false }
      isIterating = true
      return true
    }
    precondition(
      canStart,
      "AsyncUnicastChannel allows a single iterator at a time. " +
      "This is required to keep state transitions deterministic."
    )
    return Iterator(channel: self)
  }

  var queuedElements: any Collection<Element> {
    stateMachine.apply { $0.queuedElements }
  }

  var isFinishedWithoutElements: Bool {
    stateMachine.apply { $0.isFinishedWithoutElements }
  }

  var isFinished: Bool {
    stateMachine.apply { $0.isFinished }
  }

  var hasActiveIterator: Bool {
    isIteratingStorage.withLock { $0 }
  }

  func iterationDidFinish() {
    isIteratingStorage.withLock { $0 = false }
  }
}
