import StateMachineCore
import SwiftUI

// MARK: - RootView

public struct RootView: View {
  // MARK: - Lifecycle

  // MARK: Public

  public init() { }

  // MARK: - Properties

  // MARK: Public

  public var body: some View {
    StateMachineView(factory: stateMachineFactory) { uiStateMachine in
      VStack(alignment: .center) {
        if uiStateMachine.state.isLoading {
          ProgressView()
            .padding()
        } else {
          Text("Press the load button several times in a 5s time window")
            .multilineTextAlignment(.center)
            .opacity(uiStateMachine.state.canLoad ? 1 : 0.5)
            .padding()
        }

        Spacer()

        Text("Number of loads: \(uiStateMachine.state.numberOfLoads)")

        Spacer()

        HStack {
          Button("Load") {
            uiStateMachine.send(DidRequestLoading())
          }
          .padding()
          .opacity(uiStateMachine.state.canLoad ? 1 : 0.5)
          .disabled(!uiStateMachine.state.canLoad)
          .buttonStyle(.borderedProminent)

          Button("Reset") {
            uiStateMachine.send(DidRequestReset())
          }
          .padding()
          .opacity(uiStateMachine.state.canReset ? 1 : 0.5)
          .disabled(!uiStateMachine.state.canReset)
          .buttonStyle(.borderedProminent)
        }
      }
    }
    .navigationTitle(Text("Clics"))
  }

  // MARK: Private

  @Environment(\.clicsStateMachineFactory) private var stateMachineFactory
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
      .environment(\.clicsStateMachineFactory, .default(initial: DataIsIdle()))
      .previewDisplayName("Data is idle")

    RootView()
      .environment(\.clicsStateMachineFactory, .default(initial: DataIsLoading()))
      .previewDisplayName("Data is loading")

    RootView()
      .environment(\.clicsStateMachineFactory, .default(initial: DataIsLoaded(numberOfLoads: 3)))
      .previewDisplayName("Data is loaded")
  }
}
