import SwiftUI

public struct RootView: View {

  // MARK: - Lifecycle

  public init() { }

  // MARK: - Properties

  public var body: some View {
    VStack {
      ScrollView {
        WalletFullView()
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 10))
          .shadow(radius: 10)
          .padding()

        WalletAddCreditsView()
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 10))
          .shadow(radius: 10)
          .padding()

        WalletReadOnlyFullView()
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 10))
          .shadow(radius: 10)
          .padding()
      }
    }
  }
}

#Preview {
  RootView()
}
