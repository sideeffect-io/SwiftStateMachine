import Foundation

/// A receive-only stream of lifecycle contexts emitted by machines that opted
/// into `activateBroadcast()`.
public struct StateContextBroadcaster: Sendable {
  public let stream: AsyncStream<StateContext>

  private let continuation: AsyncStream<StateContext>.Continuation

  init(stream: AsyncStream<StateContext>, continuation: AsyncStream<StateContext>.Continuation) {
    self.stream = stream
    self.continuation = continuation
  }

  /// Stops this subscriber and releases its continuation from the global
  /// registry. It is safe to call more than once.
  public func stop() {
    continuation.finish()
  }
}
