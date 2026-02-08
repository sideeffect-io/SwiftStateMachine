import CheckinStateMachine
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

// swiftlint:disable no_directStandardOutLogs
let checkinStateMachineFactory = AsyncStateMachineFactory {
  let asyncStateMachine = CheckinStateMachine.asyncStateMachine
  asyncStateMachine.connectAsReceiver(to: checkinMediator)
  asyncStateMachine.onLifecycleEvent { event in
    print("----->>>>> Sending Analytics Event: CheckinNavigation \(event)")
  }

  #if DEBUG
  asyncStateMachine.activateDump()
  #endif

  return asyncStateMachine
}
