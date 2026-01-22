import StateMachineCore
import SwiftUI

// MARK: - TensView

struct TensView: View {
  // MARK: - Lifecycle

  // MARK: Public

  public init() { }

  // MARK: - Properties

  // MARK: Public

  var body: some View {
    StateMachineView(factory: stateMachineFactory) { uiStateMachine in
      Text("Tens: \(uiStateMachine.state.value)")
        .font(
          .system(
            size: 48,
            weight: .bold,
            design: Font.Design.rounded
          )
        )
    }
  }

  // MARK: Private

  @Environment(\.tensStateMachineFactory) private var stateMachineFactory
}

// MARK: - TensView_Previews

struct TensView_Previews: PreviewProvider {
  static var previews: some View {
    TensView()
      .environment(\.tensStateMachineFactory, .default(initial: TensState(value: 5)))
      .previewDisplayName("Tens 5")
  }
}
