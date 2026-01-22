import MusicStateMachine
import StateMachineCore
#if DEBUG
import StateMachineDump
#endif

// swiftlint:disable no_directStandardOutLogs
let musicStateMachineFactory = AsyncStateMachineFactory {
  let asyncStateMachine = MusicStateMachine.asyncStateMachine
  asyncStateMachine.connectAsReceiver(to: musicMediator)
  asyncStateMachine.onTransition { _, _, event, _ in
    print("----->>>>> Sending Analytics Event: MusicNavigation \(event.description)")
  }

  #if DEBUG
  asyncStateMachine.activateDump()
  #endif

  return asyncStateMachine
}
