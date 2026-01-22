import StateMachineCore
import SwiftUI

// MARK: - UnitsView

struct UnitsView: View {

  // MARK: - Properties

  // MARK: Internal

  var body: some View {
    StateMachineView(factory: stateMachineFactory, mapping: makeUIState(state:)) { uiStateMachine in
      VStack(alignment: .center) {
        Spacer()

        Text("Units: \(uiStateMachine.state.unitsState.value)")
          .font(
            .system(
              size: 48,
              weight: .bold,
              design: Font.Design.rounded
            )
          )
          .foregroundColor(uiStateMachine.state.color)

        Spacer()

        HStack {
          Spacer()

          Button {
            uiStateMachine.send(DidRequestDecrease())
          } label: {
            Image(systemName: "minus")
          }
          .opacity(uiStateMachine.state.unitsState.canDecrease ? 1 : 0.5)
          .disabled(!uiStateMachine.state.unitsState.canDecrease)

          Spacer()

          Button {
            uiStateMachine.send(DidRequestIncrease())
          } label: {
            Image(systemName: "plus")
          }

          Spacer()
        }
        .font(
          .system(
            size: 32,
            weight: .bold,
            design: Font.Design.rounded
          )
        )
      }
    }
  }

  // MARK: Private

  @Environment(\.unitsStateMachineFactory) private var stateMachineFactory
}

// MARK: - UnitsView_Previews

struct UnitsView_Previews: PreviewProvider {
  static var previews: some View {
    UnitsView()
      .environment(\.unitsStateMachineFactory, .default(initial: ValueIsFixed(value: 0)))
      .previewDisplayName("Value is fixed 0")

    UnitsView()
      .environment(\.unitsStateMachineFactory, .default(initial: ValueIsFixed(value: 5)))
      .previewDisplayName("Value is fixed 5")

    UnitsView()
      .environment(\.unitsStateMachineFactory, .default(initial: ValueIsIncreasing(value: 10)))
      .previewDisplayName("Value is increasing")

    UnitsView()
      .environment(\.unitsStateMachineFactory, .default(initial: ValueIsDecreasing(value: 10)))
      .previewDisplayName("Value is decreasing")
  }
}
