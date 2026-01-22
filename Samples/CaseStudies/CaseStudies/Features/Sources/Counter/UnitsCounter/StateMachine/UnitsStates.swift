import StateMachineCore

// MARK: - UnitsState

public struct UnitsState: Equatable {
  public let value: UInt
  let canDecrease: Bool
  let isIncreasing: Bool
  let isDecreasing: Bool
}

// MARK: - ValueIsFixed

public struct ValueIsFixed: Equatable {
  let value: UInt
}

// MARK: - ValueIsIncreasing

public struct ValueIsIncreasing: Equatable {
  let value: UInt
}

// MARK: - ValueIsDecreasing

public struct ValueIsDecreasing: Equatable {
  let value: UInt
}

// MARK: - ValueIsFixed + State

extension ValueIsFixed: State {
  public var superState: UnitsState {
    UnitsState(
      value: value,
      canDecrease: value > 0,
      isIncreasing: false,
      isDecreasing: false
    )
  }

  public var description: String {
    "ValueIsFixed (value: \(value))"
  }
}

// MARK: - ValueIsIncreasing + State

extension ValueIsIncreasing: State {
  public var superState: UnitsState {
    UnitsState(
      value: value,
      canDecrease: true,
      isIncreasing: true,
      isDecreasing: false
    )
  }

  public var description: String {
    "ValueIsIncreasing (value: \(value))"
  }
}

// MARK: - ValueIsDecreasing + State

extension ValueIsDecreasing: State {
  public var superState: UnitsState {
    UnitsState(
      value: value,
      canDecrease: value > 0,
      isIncreasing: false,
      isDecreasing: true
    )
  }

  public var description: String {
    "ValueIsDecreasing (value: \(value))"
  }
}
