extension AsyncSequence {
  /// Type erases any ``AsyncSequence`` of ``Event`` into a single type.
  /// Since ``AsyncSequence`` does not have a primary associatedtype yet, we have to erase it if we want to use it in a code
  /// where only the ``Element`` matters.
  /// - Returns: A type erased ``AsyncEventSequence``.
  func eraseToAsyncNonThrowingSequence() -> AsyncNonThrowingSequence<Element> where Self: Sendable {
    AsyncNonThrowingSequence(base: self)
  }
}

// MARK: - AsyncNonThrowingSequence

struct AsyncNonThrowingSequence<Element>: AsyncSequence, Sendable {
  typealias Element = Element
  typealias AsyncIterator = AsyncNonThrowingIterator<Element>

  // Disabling formatting rule until
  // [SwiftFormat's Issue 1341](https://github.com/nicklockwood/SwiftFormat/issues/1341) is fixed.
  // swiftformat:disable:next wrapAttributes
  let makeAsyncIteratorClosure: @Sendable () -> AsyncIterator

  init<Base: AsyncSequence>(base: Base) where Base.Element == Element, Base: Sendable {
    makeAsyncIteratorClosure = { AsyncNonThrowingIterator(base: base.makeAsyncIterator()) }
  }

  init(factory: @Sendable @escaping () async -> Element?) {
    self.init(base: AsyncJustSequence(factory))
  }

  func makeAsyncIterator() -> AsyncIterator {
    makeAsyncIteratorClosure()
  }
}

// MARK: - AsyncNonThrowingIterator

struct AsyncNonThrowingIterator<Element>: AsyncIteratorProtocol {
  typealias Element = Element

  let nextClosure: () async -> Element?

  init<Base: AsyncIteratorProtocol>(base: Base) where Base.Element == Element {
    var mutableBase = base
    nextClosure = { try? await mutableBase.next() }
  }

  mutating func next() async -> Element? {
    await nextClosure()
  }
}

// MARK: - AsyncJustSequence

struct AsyncJustSequence<Element>: AsyncSequence, Sendable {
  // MARK: - Lifecycle

  // MARK: Internal

  init(_ element: @Sendable @escaping () async -> Element?) {
    self.element = element
  }

  // MARK: - Types

  // MARK: Internal

  struct Iterator: AsyncIteratorProtocol {
    let element: @Sendable () async -> Element?
    var hasDelivered = false

    init(_ element: @Sendable @escaping () async -> Element?) {
      self.element = element
    }

    mutating func next() async -> Element? {
      guard !Task.isCancelled else { return nil }

      guard !hasDelivered else {
        return nil
      }

      hasDelivered = true
      return await element()
    }
  }

  // MARK: - Typealiases

  // MARK: Internal

  typealias Element = Element
  typealias AsyncIterator = Iterator

  // MARK: - Properties

  // MARK: Internal

  // Disabling formatting rule until
  // [SwiftFormat's Issue 1341](https://github.com/nicklockwood/SwiftFormat/issues/1341) is fixed.
  // swiftformat:disable:next wrapAttributes
  let element: @Sendable () async -> Element?

  // MARK: - Methods

  // MARK: Internal

  func makeAsyncIterator() -> Iterator {
    Iterator(element)
  }
}
