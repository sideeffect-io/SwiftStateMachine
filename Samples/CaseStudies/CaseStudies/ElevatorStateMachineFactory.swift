import Elevator
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

let elevatorStateMachineFactory = AsyncStateMachineFactory {
  let stateMachine = Elevator.makeStateMachine()

  #if DEBUG
  stateMachine.activateDump(trackDeinit: false)
  #endif

  return stateMachine
}
