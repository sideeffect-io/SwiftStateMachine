import MusicStateMachine
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

// swiftlint:disable no_directStandardOutLogs
let musicStateMachineFactory = AsyncStateMachineFactory {
  let asyncStateMachine = MusicStateMachine.asyncStateMachine
  asyncStateMachine.connectAsReceiver(to: musicMediator)
asyncStateMachine.onLifecycleEvent { event in
    print("----->>>>> Sending Analytics Event: MusicNavigation \(event)")
  }

  #if DEBUG
  asyncStateMachine.activateDump()
  #endif

  return asyncStateMachine
}
