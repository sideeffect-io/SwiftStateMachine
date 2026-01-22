extension AsyncUnicastChannel {
  struct Iterator: AsyncIteratorProtocol {
    // MARK: - Properties

    // MARK: Internal

    let channel: AsyncUnicastChannel<Element>

    // MARK: - Methods

    // MARK: Internal

    mutating func next() async -> Element? {
      let element = await withTaskCancellationHandler {
        await withUnsafeContinuation { [channel] (continuation: UnsafeContinuation<Element?, Never>) in
          channel.stateMachine.apply { stateMachine in
            let action = stateMachine.newIteration(continuation: continuation)
            switch action {
            case .suspend:
              #if DEBUG
              channel.onSuspended?()
              #endif
            case .resumeDownstream(let element):
              continuation.resume(returning: element)
            }
          }
        }
      } onCancel: { [channel] in
        channel.stateMachine.apply { stateMachine in
          let action = stateMachine.iterationCancelled()
          switch action {
          case .none:
            break
          case .resumeDownstream(let continuation):
            continuation.resume(returning: nil)
          }
        }
      }

      if element == nil {
        channel.iterationDidFinish()
      }

      return element
    }
  }
}
