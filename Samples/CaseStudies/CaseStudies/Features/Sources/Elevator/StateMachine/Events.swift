import StateMachineCore

// MARK: - ElevatorEvent

public enum ElevatorEvent { }

// MARK: - DidEntered

struct DidEntered: Event {
  typealias SuperEvent = ElevatorEvent
}

// MARK: - DidLeft

struct DidLeft: Event {
  typealias SuperEvent = ElevatorEvent
}

// MARK: - DidRequestToOpen

struct DidRequestToOpen: Event {
  typealias SuperEvent = ElevatorEvent
}

// MARK: - DidRequestToClose

struct DidRequestToClose: Event {
  typealias SuperEvent = ElevatorEvent
}
