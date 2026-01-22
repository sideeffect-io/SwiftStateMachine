import StateMachineCore

// MARK: - ClicsEvent

public enum ClicsEvent { }

// MARK: - DidRequestLoading

public struct DidRequestLoading: Event {
  public typealias SuperEvent = ClicsEvent
}

// MARK: - DidCompleteLoading

public struct DidCompleteLoading: Event {
  public typealias SuperEvent = ClicsEvent
}

// MARK: - DidRequestReset

public struct DidRequestReset: Event {
  public typealias SuperEvent = ClicsEvent
}
