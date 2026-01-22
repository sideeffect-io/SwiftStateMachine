import HomeView
import SwiftUI
#if DEBUG
import StateMachineDump
#endif

// MARK: - NavigationApp

// swiftlint:disable no_directStandardOutLogs

@main
struct NavigationApp: App {

  init() {
    #if DEBUG
    StateMachineDump.startCollecting()
    #endif
  }

  var body: some Scene {
    WindowGroup {
      VStack {
        HomeView.RootView()
          .environment(\.albumStateMachineFactory, albumStateMachineFactory)
          .environment(\.albumsStateMachineFactory, albumsStateMachineFactory)
          .environment(\.checkinStateMachineFactory, checkinStateMachineFactory)
          .environment(\.musicStateMachineFactory, musicStateMachineFactory)
          .environment(\.ownerStateMachineFactory, ownerStateMachineFactory)
          .environment(\.placesStateMachineFactory, placesStateMachineFactory)
          .environment(\.placeStateMachineFactory, placeStateMachineFactory)
          .environment(\.songStateMachineFactory, songStateMachineFactory)

        #if DEBUG
        Divider()
          .padding(0)

        Button {
          StateMachineDump.dump { stateContexts in
            print("----------------- DUMP -----------------")
            stateContexts.forEach { stateContext in
              let superStateType = type(of: stateContext.state.superState)
              let currentState = stateContext.state
              let timeStamp = stateContext.timeStamp
              print("[\(superStateType)] \(currentState) at \(timeStamp)")
            }
          }
        } label: {
          Text("Dump")
        }
        .buttonStyle(.borderedProminent)
        #endif
      }
    }
  }
}
