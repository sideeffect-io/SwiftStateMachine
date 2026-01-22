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
        Text(
          "Press the 'New analysis' button to start an analysis. While performing you can reset it or wait until completion."
        )
        .multilineTextAlignment(.center)
        .padding()

        Spacer()

        Text(uiStateMachine.state.message)

        Spacer()

        HStack {
          Button {
            uiStateMachine.send(DidRequestAnalysis(identifier: Int.random(in: 1...1_000)))
          } label: {
            Text("New analysis")
          }
          .padding()
          .background(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke().foregroundColor(.blue))
          .opacity(uiStateMachine.state.canMakeNewAnalysis ? 1 : 0.5)
          .disabled(!uiStateMachine.state.canMakeNewAnalysis)

          Button {
            uiStateMachine.send(DidRequestAnalysisReset())
          } label: {
            Text("Reset analysis")
          }
          .padding()
          .background(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke().foregroundColor(.blue))
          .opacity(uiStateMachine.state.canResetAnalysis ? 1 : 0.5)
          .disabled(!uiStateMachine.state.canResetAnalysis)
        }
      }
    }
    .navigationTitle(Text("Analysis"))
  }

  // MARK: Private

  @Environment(\.analysisStateMachineFactory) private var stateMachineFactory
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
      .environment(\.analysisStateMachineFactory, .default(initial: AnalysisIsIdle()))
      .previewDisplayName("Analysis is idle")

    RootView()
      .environment(\.analysisStateMachineFactory, .default(initial: AnalysisIsInProgress(identifier: 1)))
      .previewDisplayName("Analysis is in progress")

    RootView()
      .environment(\.analysisStateMachineFactory, .default(initial: AnalysisIsDone(identifier: 1)))
      .previewDisplayName("Analysis is done")
  }
}
