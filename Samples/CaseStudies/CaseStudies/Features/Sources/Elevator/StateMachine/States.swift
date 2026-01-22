import StateMachineCore

// MARK: - ElevatorState

public struct ElevatorState: Equatable {
  let numberOfPersons: String
  let canAddPerson: Bool
  let canRemovePerson: Bool
  let canPressOpen: Bool
  let canPressClose: Bool
  let symbol: String
  let message: String
}

// MARK: - ElevatorIsOpen

struct ElevatorIsOpen: Equatable {
  let persons: Int
}

// MARK: - ElevatorIsClosed

struct ElevatorIsClosed: Equatable {
  let persons: Int
}

// MARK: - ElevatorIsInWarning

struct ElevatorIsInWarning: Equatable {
  let persons: Int
}

// MARK: - ElevatorIsOpen + State

extension ElevatorIsOpen: State {
  var superState: ElevatorState {
    ElevatorState(
      numberOfPersons: "\(persons)",
      canAddPerson: true,
      canRemovePerson: persons > 0,
      canPressOpen: false,
      canPressClose: true,
      symbol: "lock.open.fill",
      message: "More people can enter, or you can close the elevator"
    )
  }

  var description: String {
    "ElevatorIsOpen (persons: \(persons))"
  }
}

// MARK: - ElevatorIsClosed + State

extension ElevatorIsClosed: State {
  var superState: ElevatorState {
    ElevatorState(
      numberOfPersons: "\(persons)",
      canAddPerson: false,
      canRemovePerson: false,
      canPressOpen: true,
      canPressClose: false,
      symbol: "lock.fill",
      message: "You can open the elevator"
    )
  }

  var description: String {
    "ElevatorIsClose (persons: \(persons))"
  }
}

// MARK: - ElevatorIsInWarning + State

extension ElevatorIsInWarning: State {
  var superState: ElevatorState {
    ElevatorState(
      numberOfPersons: "\(persons)",
      canAddPerson: true,
      canRemovePerson: true,
      canPressOpen: false,
      canPressClose: false,
      symbol: "exclamationmark.triangle.fill",
      message: "Too many people, some should leave"
    )
  }

  var description: String {
    "ElevatorIsInWarning (persons: \(persons))"
  }
}
