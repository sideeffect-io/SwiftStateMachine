import StateMachineCore

// MARK: - TensState

public struct TensState: State, Equatable {
  public var superState: Self {
    self
  }

  let value: UInt

  public var description: String {
    "Value (\(value))"
  }
}
