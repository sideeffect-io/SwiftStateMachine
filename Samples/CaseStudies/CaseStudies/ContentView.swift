import Analysis
import Clics
import Counter
import Elevator
import SwiftUI
import Wallet
#if DEBUG
import StateMachineDump
#endif

// MARK: - ContentView

// swiftlint:disable no_directStandardOutLogs

struct ContentView: View {

  // MARK: - Properties

  // MARK: Internal

  var body: some View {
    VStack {
      NavigationStack {
        List {
          NavigationLink(
            destination: Clics
              .RootView()
              .environment(\.clicsStateMachineFactory, clicsCancellingStateMachineFactory),
            label: {
              Text("Clics sample (cancel output)")
            }
          )

          NavigationLink(
            destination: Clics
              .RootView()
              .environment(\.clicsStateMachineFactory, clicsContinuingStateMachineFactory),
            label: {
              Text("Clics sample (continue output)")
            }
          )

          NavigationLink(
            destination: Counter.RootView(),
            label: {
              Text("Counter sample (mediator)")
            }
          )

          NavigationLink(
            destination: Elevator.RootView(),
            label: {
              Text("Elevator sample (simple transitions)")
            }
          )

          NavigationLink(
            destination: Analysis.RootView(),
            label: {
              Text("Analysis sample (simple output)")
            }
          )

          NavigationLink(
            destination: Wallet.RootView(),
            label: {
              Text("Wallet sample (shared state machine)")
            }
          )
        }
        .navigationTitle(Text("CaseStudies"))
      }

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
      .padding()
      #endif
    }
  }
}

// MARK: - ContentViewPreviews

#Preview {
  ContentView()
}
