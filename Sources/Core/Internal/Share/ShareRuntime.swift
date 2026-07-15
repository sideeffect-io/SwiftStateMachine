import os

/// Owns a shared base iteration independently from individual subscriber
/// iterators. Subscribers are represented by leases, so abandoning an iterator
/// removes its channel immediately instead of retaining an unbounded buffer.
final class ShareRuntime<Base: AsyncSequence>: @unchecked Sendable
  where Base: Sendable, Base.Element: Sendable
{
  typealias Element = Base.Element

  private struct State {
    var nextID = 0
    var clients: [Int: AsyncUnicastChannel<Element>] = [:]
    var replay: [Element] = []
    var hasStarted = false
    var isFinished = false
    var driver: Task<Void, Never>?
  }

  private let base: Base
  private let replayCount: ReplayCount
  private let state = OSAllocatedUnfairLock(initialState: State())

  init(base: Base, replayCount: ReplayCount) {
    self.base = base
    self.replayCount = replayCount
  }

  deinit {
    state.withLock { $0.driver?.cancel() }
  }

  func makeClient() -> (id: Int, channel: AsyncUnicastChannel<Element>, lease: ClientLease) {
    let id = state.withLock { state in
      state.nextID += 1
      return state.nextID
    }
    let channel = AsyncUnicastChannel<Element>()
    return (id, channel, ClientLease(runtime: self, id: id, channel: channel))
  }

  /// Registers demand for one client. The lease's cancelled flag is checked on
  /// both sides of registration, closing cancellation-before-registration races.
  func request(
    clientID: Int,
    channel: AsyncUnicastChannel<Element>,
    lease: ClientLease
  ) -> Bool {
    guard !lease.isEnded else { return false }

    let action = state.withLock { state -> RequestAction in
      if state.isFinished {
        return .replayAndFinish(state.replay)
      }

      var replay: [Element] = []
      if state.clients[clientID] == nil {
        state.clients[clientID] = channel
        replay = state.replay
      }

      if !state.hasStarted {
        state.hasStarted = true
        return .start(replay)
      }
      return .wait(replay)
    }

    // A cancellation that won the race before registration is cleaned up by
    // this second check; one after registration removes the entry in `end()`.
    guard !lease.isEnded else {
      remove(clientID: clientID, channel: channel)
      return false
    }

    switch action {
    case .start(let replay):
      replay.forEach { _ = channel.send($0) }
      startDriver()
      return true
    case .wait(let replay):
      replay.forEach { _ = channel.send($0) }
      return true
    case .replayAndFinish(let replay):
      replay.forEach { _ = channel.send($0) }
      channel.finish()
      return true
    }
  }

  fileprivate func remove(clientID: Int, channel: AsyncUnicastChannel<Element>) {
    let removed = state.withLock { state -> AsyncUnicastChannel<Element>? in
      guard let registered = state.clients.removeValue(forKey: clientID) else { return nil }
      return registered
    }
    // `removed` is normally `channel`; retain the supplied reference to make
    // the ownership relationship explicit and finish outside the lock.
    (removed ?? channel).finish()
  }

  private func startDriver() {
    let driver = Task { [base, weak self] in
      do {
        var iterator = base.makeAsyncIterator()
        while !Task.isCancelled, let element = try await iterator.next() {
          self?.broadcast(element)
        }
      } catch {
        // `share` is intentionally non-throwing for source compatibility.
        // A failing base is treated as a finished shared sequence.
      }
      self?.finish()
    }
    state.withLock { $0.driver = driver }
  }

  private func broadcast(_ element: Element) {
    let clients = state.withLock { state -> [AsyncUnicastChannel<Element>] in
      guard !state.isFinished else { return [] }
      switch replayCount {
      case .unbounded:
        state.replay.append(element)
      case .max(0):
        break
      case .max(let count):
        if state.replay.count >= count {
          state.replay.removeFirst()
        }
        state.replay.append(element)
      }
      return Array(state.clients.values)
    }
    clients.forEach { _ = $0.send(element) }
  }

  private func finish() {
    let clients = state.withLock { state -> [AsyncUnicastChannel<Element>] in
      guard !state.isFinished else { return [] }
      state.isFinished = true
      state.driver = nil
      let clients = Array(state.clients.values)
      state.clients.removeAll()
      return clients
    }
    clients.forEach { $0.finish() }
  }

  private enum RequestAction {
    case start([Element])
    case wait([Element])
    case replayAndFinish([Element])
  }

  final class ClientLease: @unchecked Sendable {
    private weak var runtime: ShareRuntime?
    private let clientID: Int
    private let channel: AsyncUnicastChannel<Element>
    private let ended = OSAllocatedUnfairLock(initialState: false)

    init(runtime: ShareRuntime, id: Int, channel: AsyncUnicastChannel<Element>) {
      self.runtime = runtime
      clientID = id
      self.channel = channel
    }

    deinit {
      end()
    }

    var isEnded: Bool {
      ended.withLock { $0 }
    }

    func end() {
      let shouldEnd = ended.withLock { value in
        guard !value else { return false }
        value = true
        return true
      }
      guard shouldEnd else { return }
      runtime?.remove(clientID: clientID, channel: channel)
    }
  }
}
