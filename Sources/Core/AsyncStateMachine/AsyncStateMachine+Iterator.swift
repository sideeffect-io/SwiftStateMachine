extension AsyncStateMachine {
  public struct Iterator: AsyncIteratorProtocol {
    private var stateIterator: AsyncUnicastChannel<AnyState>.Iterator

    init(stateIterator: AsyncUnicastChannel<AnyState>.Iterator) {
      self.stateIterator = stateIterator
    }

    public mutating func next() async -> Element? {
      await stateIterator.next()
    }
  }
}
