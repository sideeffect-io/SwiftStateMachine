import Clics
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

let clicsCancellingStateMachineFactory = AsyncStateMachineFactory {
  let loadOutput = LoadOutput {
    // simulating heavy duty by just waiting for 5s
    try await Task.sleep(until: .now + .seconds(5), clock: .continuous)
  }
  let stateMachine = Clics.makeCancellingStateMachine(load: loadOutput)

  #if DEBUG
  stateMachine.activateDump(trackDeinit: false)
  #endif

  return stateMachine
}

let clicsContinuingStateMachineFactory = AsyncStateMachineFactory {
  let loadOutput = LoadOutput {
    // simulating heavy duty by just waiting for 5s
    try await Task.sleep(until: .now + .seconds(5), clock: .continuous)
  }
  let stateMachine = Clics.makeContinuingStateMachine(load: loadOutput)

  #if DEBUG
  stateMachine.activateDump(trackDeinit: false)
  #endif

  return stateMachine
}
