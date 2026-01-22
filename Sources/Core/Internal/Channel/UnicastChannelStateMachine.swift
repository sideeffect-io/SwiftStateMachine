@_implementationOnly import DequeModule

struct UnicastChannelStateMachine<Element>: Sendable where Element: Sendable {

  // MARK: - Types

  // MARK: Internal

  enum FinishAction {
    case none
    case resumeDownstream(continuation: UnsafeContinuation<Element?, Never>)
  }

  enum IterationCancelledAction {
    case none
    case resumeDownstream(continuation: UnsafeContinuation<Element?, Never>)
  }

  enum NewElementAction {
    case none
    case resumeDownstream(continuation: UnsafeContinuation<Element?, Never>)
  }

  enum NewIterationAction {
    case suspend
    case resumeDownstream(element: Element?)
  }

  enum State: Sendable {
    case idle
    case buffering(elements: Deque<Element>)
    case waitingForUpstream(continuation: UnsafeContinuation<Element?, Never>)
    case modifying
    case finished(elements: Deque<Element>?)
  }

  // MARK: - Properties

  // MARK: Internal

  var queuedElements: any Collection<Element> {
    switch state {
    case .buffering(let elements):
      elements
    case .finished(let elements):
      elements ?? []
    case .idle, .waitingForUpstream, .modifying:
      []
    }
  }

  var isFinishedWithoutElements: Bool {
    switch state {
    case .finished(let elements) where elements == nil || elements?.isEmpty == true:
      true
    default:
      false
    }
  }

  var isFinished: Bool {
    if case .finished = state {
      return true
    }
    return false
  }

  // MARK: Private

  private var state: State = .idle

  // MARK: - Methods

  // MARK: Internal

  mutating func newElement(_ element: Element) -> NewElementAction {
    switch state {
    case .idle:
      state = .buffering(elements: [element])
      return .none
    case .buffering(var elements):
      state = .modifying
      elements.append(element)
      state = .buffering(elements: elements)
      return .none
    case .waitingForUpstream(let continuation):
      state = .idle
      return .resumeDownstream(continuation: continuation)
    case .modifying:
      preconditionFailure("Invalid state.")
    case .finished:
      return .none
    }
  }

  mutating func newIteration(
    continuation: UnsafeContinuation<Element?, Never>
  ) -> NewIterationAction {
    switch state {
    case .idle:
      state = .waitingForUpstream(continuation: continuation)
      return .suspend
    case .buffering(var elements):
      precondition(!elements.isEmpty, "Invalid state.")
      state = .modifying
      let element = elements.popFirst()!
      if elements.isEmpty {
        state = .idle
      } else {
        state = .buffering(elements: elements)
      }
      return .resumeDownstream(element: element)
    case .waitingForUpstream:
      preconditionFailure("Invalid state.")
    case .modifying:
      preconditionFailure("Invalid state.")
    case .finished(.none):
      return .resumeDownstream(element: nil)
    case .finished(.some(var elements)):
      precondition(!elements.isEmpty, "Invalid state.")
      state = .modifying
      let element = elements.popFirst()!
      if elements.isEmpty {
        state = .finished(elements: nil)
      } else {
        state = .finished(elements: elements)
      }
      return .resumeDownstream(element: element)
    }
  }

  mutating func iterationCancelled() -> IterationCancelledAction {
    switch state {
    case .idle:
      return .none
    case .buffering:
      return .none
    case .waitingForUpstream(let continuation):
      state = .idle
      return .resumeDownstream(continuation: continuation)
    case .modifying:
      preconditionFailure("Invalid state.")
    case .finished:
      state = .finished(elements: nil)
      return .none
    }
  }

  mutating func finish() -> FinishAction {
    switch state {
    case .idle:
      state = .finished(elements: nil)
      return .none
    case .buffering(let elements):
      state = .finished(elements: elements)
      return .none
    case .waitingForUpstream(let continuation):
      state = .finished(elements: nil)
      return .resumeDownstream(continuation: continuation)
    case .modifying:
      preconditionFailure("Invalid state.")
    case .finished:
      return .none
    }
  }
}
