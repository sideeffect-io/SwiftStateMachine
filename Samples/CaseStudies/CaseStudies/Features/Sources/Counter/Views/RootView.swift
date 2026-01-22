import StateMachineCore
import SwiftUI

// MARK: - RootView

public struct RootView: View {
  // MARK: - Lifecycle

  public init() { }

  // MARK: - Properties

  // MARK: Public

  public var body: some View {
    VStack {
      VStack {
        Spacer()
        UnitsView()
        Spacer()
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(.gray)
      .clipShape(
        RoundedRectangle(
          cornerRadius: 15,
          style: .continuous
        )
      )
      .padding(30)
      .shadow(radius: 10)

      Label {
        Text("linked to")
      } icon: {
        Image(systemName: "arrow.down")
      }

      VStack {
        Spacer()
        TensView()
        Spacer()
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(.blue)
      .clipShape(
        RoundedRectangle(
          cornerRadius: 15,
          style: .continuous
        )
      )
      .padding(30)
      .shadow(radius: 10)
    }
    .navigationTitle(Text("Counter"))
  }
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
