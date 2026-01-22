import StateMachineCore
import Wallet
#if DEBUG
import StateMachineDump
#endif

let walletStateMachineFactory = AsyncStateMachineFactory(lifecycle: .singleton) {
  let stateMachine = Wallet.makeStateMachine()

  #if DEBUG
  stateMachine.activateDump(trackDeinit: false)
  #endif

  return stateMachine
}
