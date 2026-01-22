import StateMachineCore

// MARK: - Idle

struct Idle { let seed = Int.random(in: 0...100) }

// MARK: - Loading

struct Loading { let seed = Int.random(in: 0...100) }

// MARK: - Loaded

struct Loaded { let value: Int }

// MARK: - Failed

struct Failed { let error: MockError }

// MARK: - MockSuperState

struct MockSuperState: Equatable {
  let isLoaded: Bool
  let isFailed: Bool
}

// MARK: - Idle + State, Equatable

extension Idle: State, Equatable {
  var superState: MockSuperState {
    SuperState(isLoaded: false, isFailed: false)
  }
}

// MARK: - Loading + State, Equatable

extension Loading: State, Equatable {
  var superState: MockSuperState {
    SuperState(isLoaded: false, isFailed: false)
  }
}

// MARK: - Loaded + State, Equatable

extension Loaded: State, Equatable {
  var superState: MockSuperState {
    SuperState(isLoaded: true, isFailed: false)
  }
}

// MARK: - Failed + State, Equatable

extension Failed: State, Equatable {
  var superState: MockSuperState {
    SuperState(isLoaded: false, isFailed: true)
  }
}

// MARK: - SenderIdle

struct SenderIdle { let seed = Int.random(in: 0...100) }

// MARK: - SenderLoading

struct SenderLoading { let seed = Int.random(in: 0...100) }

// MARK: - SenderLoaded

struct SenderLoaded { let seed = Int.random(in: 0...100) }

// MARK: - SenderMockSuperState

struct SenderMockSuperState: Equatable {
  let isLoaded: Bool
}

// MARK: - SenderIdle + State, Equatable

extension SenderIdle: State, Equatable {
  var superState: SenderMockSuperState {
    SuperState(isLoaded: false)
  }
}

// MARK: - SenderLoading + State, Equatable

extension SenderLoading: State, Equatable {
  var superState: SenderMockSuperState {
    SuperState(isLoaded: false)
  }
}

// MARK: - SenderLoaded + State, Equatable

extension SenderLoaded: State, Equatable {
  var superState: SenderMockSuperState {
    SuperState(isLoaded: true)
  }
}
