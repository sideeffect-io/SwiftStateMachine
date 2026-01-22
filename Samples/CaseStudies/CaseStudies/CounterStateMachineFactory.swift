import Counter
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

let counterMediator = Mediator<TensEvent>()

let counterUnitsStateMachineFactory = AsyncStateMachineFactory {
  let unitsStateMachine = Counter.makeUnitsStateMachine()
  unitsStateMachine.connectAsSender(to: counterMediator) { _, _, _, newUnitState in
    let tens = newUnitState.superState.value / 10
    return TensEvent(value: UInt(tens))
  }

  #if DEBUG
  unitsStateMachine.activateDump(trackDeinit: false)
  #endif

  return unitsStateMachine
}

let counterTensStateMachineFactory = AsyncStateMachineFactory {
  let tensStateMachine = Counter.makeTensStateMachine()
  tensStateMachine.connectAsReceiver(to: counterMediator)

  #if DEBUG
  tensStateMachine.activateDump(trackDeinit: false)
  #endif

  return tensStateMachine
}
