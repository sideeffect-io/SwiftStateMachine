import StateMachineCore

// MARK: - UnitsEvent

public enum UnitsEvent { }

// MARK: - DidRequestIncrease

public struct DidRequestIncrease: Event {
  public typealias SuperEvent = UnitsEvent
}

// MARK: - DidRequestDecrease

public struct DidRequestDecrease: Event {
  public typealias SuperEvent = UnitsEvent
}
