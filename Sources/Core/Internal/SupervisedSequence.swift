import StateMachineShared

struct SupervisedSequence<Element>: AsyncSequence, @unchecked Sendable {
  typealias AsyncIterator = Iterator

  let makeAsyncIteratorClosure: () -> Iterator
  let errorStorage: SendableStorage<Error?>

  init<Base: AsyncSequence>(base: Base) where Base: Sendable, Base.Element == Element {
    let errorStorage = SendableStorage<Error?>(value: nil)
    self.errorStorage = errorStorage
    makeAsyncIteratorClosure = {
      var iterator = base.makeAsyncIterator()
      return Iterator { [errorStorage] in
        do {
          return try await iterator.next()
        } catch {
          errorStorage.set(value: error)
          return nil
        }
      }
    }
  }

  func makeAsyncIterator() -> Iterator {
    makeAsyncIteratorClosure()
  }

  func failure() -> Error? {
    errorStorage.get()
  }

  struct Iterator: AsyncIteratorProtocol {
    let nextClosure: () async -> Element?

    init(_ nextClosure: @escaping () async -> Element?) {
      self.nextClosure = nextClosure
    }

    mutating func next() async -> Element? {
      await nextClosure()
    }
  }
}
