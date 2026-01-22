import Foundation

/// Use the StateContextBroadcaster.stream to iterate on the broadcasted state contexts.
public struct StateContextBroadcaster {

  /// The stream of the broadcasred state contexts
  public let stream: AsyncStream<StateContext>
  let id: UUID
  let monitor: StateContextMonitor
  let continuation: AsyncStream<StateContext>.Continuation

  /// Call stop to stop monitoring the state changes. This will also allow to deallocate the stream.
  public func stop() {
    continuation.finish()
  }

}
