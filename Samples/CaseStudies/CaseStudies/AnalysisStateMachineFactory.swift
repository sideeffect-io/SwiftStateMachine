import Analysis
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

let analysisStateMachineFactory = AsyncStateMachineFactory {
  let performAnalysisOutput = PerformAnalysisOutput {
    // simulating heavy duty by just waiting for 3s
    try? await Task.sleep(until: .now + .seconds(3), clock: .continuous)
  }
  let stateMachine = Analysis.makeStateMachine(performAnalysisOutput: performAnalysisOutput)

  #if DEBUG
  stateMachine.activateDump(trackDeinit: false)
  #endif

  return stateMachine
}
