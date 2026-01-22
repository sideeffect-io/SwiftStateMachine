import StateMachineCore
import SwiftUI

struct WalletAddCreditsView: View {

  // MARK: - Properties

  var body: some View {
    StateMachineView(factory: stateMachineFactory) { stateMachine in
      VStack {
        HStack {
          Text("Wallet Add View, credits:")
          Text(stateMachine.state.credits, format: .currency(code: "USD"))
        }

        HStack {
          Slider(value: $credits, in: 0...100)
          Text(credits, format: .currency(code: "USD"))
        }

        Button {
          stateMachine.send(DidRequestToAddCreditsEvent(credits: credits))
          credits = 0.0
        } label: {
          Text("Add credits")
        }
        .buttonStyle(.borderedProminent)
      }
    }.padding(.all)
  }

  @SwiftUI.State var credits = 0.0
  @Environment(\.walletStateMachineFactory) private var stateMachineFactory
}

#Preview {
  WalletAddCreditsView()
}
