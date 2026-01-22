import StateMachineCore

// MARK: - AnalysisState

public struct AnalysisState: Equatable {
  let message: String
  let canMakeNewAnalysis: Bool
  let canResetAnalysis: Bool
}

// MARK: - AnalysisIsIdle

struct AnalysisIsIdle: Equatable { }

// MARK: - AnalysisIsInProgress

struct AnalysisIsInProgress: Equatable {
  let identifier: Int
}

// MARK: - AnalysisIsDone

struct AnalysisIsDone: Equatable {
  let identifier: Int
}

// MARK: - AnalysisIsIdle + State

extension AnalysisIsIdle: State {
  var superState: AnalysisState {
    AnalysisState(
      message: "Ready to start a new analysis",
      canMakeNewAnalysis: true,
      canResetAnalysis: false
    )
  }
}

// MARK: - AnalysisIsInProgress + State

extension AnalysisIsInProgress: State {
  var superState: AnalysisState {
    AnalysisState(
      message: "Analysis in progress (id = \(identifier))",
      canMakeNewAnalysis: false,
      canResetAnalysis: true
    )
  }
}

// MARK: - AnalysisIsDone + State

extension AnalysisIsDone: State {
  var superState: AnalysisState {
    AnalysisState(
      message: "Analysis is finished (id = \(identifier))",
      canMakeNewAnalysis: false,
      canResetAnalysis: true
    )
  }
}
