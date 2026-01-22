import SwiftUI
#if DEBUG
import StateMachineDump
#endif

// MARK: - CaseStudiesApp

@main
struct CaseStudiesApp: App {
  init() {
    #if DEBUG
    StateMachineDump.startCollecting()
    #endif
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(\.analysisStateMachineFactory, analysisStateMachineFactory)
        .environment(\.unitsStateMachineFactory, counterUnitsStateMachineFactory)
        .environment(\.tensStateMachineFactory, counterTensStateMachineFactory)
        .environment(\.elevatorStateMachineFactory, elevatorStateMachineFactory)
        .environment(\.walletStateMachineFactory, walletStateMachineFactory)
    }
  }
}
