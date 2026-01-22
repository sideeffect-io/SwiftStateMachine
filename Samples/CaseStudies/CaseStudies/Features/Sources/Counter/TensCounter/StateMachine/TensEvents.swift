import StateMachineCore

// MARK: - TensEvent

public struct TensEvent: Event {
  public init(value: UInt) {
    self.value = value
  }

  public typealias SuperEvent = Self
  let value: UInt
}
