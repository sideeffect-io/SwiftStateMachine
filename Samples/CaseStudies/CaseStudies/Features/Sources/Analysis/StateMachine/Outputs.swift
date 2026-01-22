import StateMachineCore

public struct PerformAnalysisOutput {
  // MARK: - Lifecycle

  // MARK: Public

  public init(performAnalysisFunction: @Sendable @escaping () async -> Void) {
    self.performAnalysisFunction = performAnalysisFunction
  }

  // MARK: - Properties

  // MARK: Internal

  // Disabling formatting rule until
  // [SwiftFormat's Issue 1341](https://github.com/nicklockwood/SwiftFormat/issues/1341) is fixed.
  // swiftformat:disable:next wrapAttributes
  let performAnalysisFunction: @Sendable () async -> Void

  // MARK: - Methods

  // MARK: Internal

  func callAsFunction() -> @Sendable () async -> any Event<AnalysisEvent> {
    { @Sendable in
      await performAnalysisFunction()
      return DidCompleteAnalysis()
    }
  }
}
