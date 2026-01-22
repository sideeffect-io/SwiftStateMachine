import StateMachineCore
import SwiftUI

struct WalletReadOnlyFullView: View {
  // MARK: - Properties

  // MARK: Internal

  var body: some View {
    StateMachineView(factory: stateMachineFactory) { stateMachine in
      HStack {
        Text("Wallet Read Only View, credits:")
        Text(stateMachine.state.credits, format: .currency(code: "USD"))
      }
      .padding(.all)
    }
  }

  // MARK: Private

  @Environment(\.walletStateMachineFactory) private var stateMachineFactory
}

#Preview {
  WalletReadOnlyFullView()
}
