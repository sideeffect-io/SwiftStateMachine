import StateMachineCore
import SwiftUI

// MARK: - AnalysisStateMachineKey

public struct AnalysisStateMachineKey: EnvironmentKey {
  // MARK: - Properties

  // MARK: Public

  public static let defaultValue: AsyncStateMachineFactory<AnalysisState, AnalysisEvent> =
    .default(initial: AnalysisIsIdle())
}

// MARK: - EnvironmentValues + analysisStateMachineFactory

extension EnvironmentValues {
  public var analysisStateMachineFactory: AsyncStateMachineFactory<AnalysisState, AnalysisEvent> {
    get { self[AnalysisStateMachineKey.self] }
    set { self[AnalysisStateMachineKey.self] = newValue }
  }
}
