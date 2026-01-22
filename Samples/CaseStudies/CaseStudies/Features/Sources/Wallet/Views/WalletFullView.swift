import StateMachineCore
import SwiftUI

struct WalletFullView: View {
  // MARK: - Properties

  // MARK: Internal

  var body: some View {
    StateMachineView(factory: stateMachineFactory) { stateMachine in
      VStack {
        HStack {
          Text("Wallet Full View, credits:")
          Text(stateMachine.state.credits, format: .currency(code: "USD"))
        }

        TextField(text: $credits) {
          Text("Credits")
        }
        .textFieldStyle(.roundedBorder)

        Button {
          guard let doubleCredits = try? Double(credits, format: .number) else {
            credits = "0.0"
            return
          }
          stateMachine.send(DidRequestToAddCreditsEvent(credits: doubleCredits))
          credits = "0.0"
        } label: {
          Text("Add credits")
        }
        .buttonStyle(.borderedProminent)

        Button {
          guard let doubleCredits = try? Double(credits, format: .number) else {
            credits = "0.0"
            return
          }
          stateMachine.send(DidRequestToRemoveCreditsEvent(credits: doubleCredits))
          credits = "0.0"
        } label: {
          Text("Remove credits")
        }
        .buttonStyle(.borderedProminent)
      }
    }.padding(.all)
  }

  @SwiftUI.State var credits = "0.0"

  // MARK: Private

  @Environment(\.walletStateMachineFactory) private var stateMachineFactory
}

#Preview {
  WalletFullView()
}
