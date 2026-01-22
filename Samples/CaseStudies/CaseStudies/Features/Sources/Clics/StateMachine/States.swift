import StateMachineCore

// MARK: - ClicsState

public struct ClicsState: Equatable {
  let numberOfLoads: Int
  let isLoading: Bool
  let canLoad: Bool
  let canReset: Bool
}

// MARK: - DataIsIdle

public struct DataIsIdle: Equatable { }

// MARK: - DataIsLoading

public struct DataIsLoading: Equatable { }

// MARK: - DataIsLoaded

public struct DataIsLoaded: Equatable {
  let numberOfLoads: Int
}

// MARK: - DataIsIdle + State

extension DataIsIdle: State {
  public var superState: ClicsState {
    ClicsState(
      numberOfLoads: 0,
      isLoading: false,
      canLoad: true,
      canReset: false
    )
  }
}

// MARK: - DataIsLoading + State

extension DataIsLoading: State {
  public var superState: ClicsState {
    ClicsState(
      numberOfLoads: 0,
      isLoading: true,
      canLoad: true,
      canReset: false
    )
  }
}

// MARK: - DataIsLoaded + State

extension DataIsLoaded: State {
  public var superState: ClicsState {
    ClicsState(
      numberOfLoads: numberOfLoads,
      isLoading: false,
      canLoad: false,
      canReset: true
    )
  }

  public var description: String {
    "DataIsLoaded (number of loads: \(numberOfLoads))"
  }
}
