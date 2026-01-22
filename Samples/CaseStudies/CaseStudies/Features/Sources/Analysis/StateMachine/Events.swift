import StateMachineCore

// MARK: - AnalysisEvent

public enum AnalysisEvent { }

// MARK: - DidRequestAnalysis

struct DidRequestAnalysis: Event {
  typealias SuperEvent = AnalysisEvent
  let identifier: Int
}

// MARK: - DidRequestAnalysisReset

struct DidRequestAnalysisReset: Event {
  typealias SuperEvent = AnalysisEvent
}

// MARK: - DidCompleteAnalysis

struct DidCompleteAnalysis: Event {
  typealias SuperEvent = AnalysisEvent
}
