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
      VStack {
        VStack {
          Text("Rules: Make people enter or leave the elevator and try to close it")
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .padding()

          Spacer()

          HStack {
            Button {
              uiStateMachine.send(DidLeft())
            } label: {
              Image(systemName: "minus.circle.fill")
            }
            .font(.largeTitle)
            .foregroundColor(.white)
            .padding()
            .opacity(uiStateMachine.state.canRemovePerson ? 1 : 0.5)
            .disabled(!uiStateMachine.state.canRemovePerson)

            Text(uiStateMachine.state.numberOfPersons)
              .font(
                .system(
                  size: 64,
                  weight: .bold,
                  design: Font.Design.rounded
                )
              )
              .padding()

            Button {
              uiStateMachine.send(DidEntered())
            } label: {
              Image(systemName: "plus.circle.fill")
            }
            .font(.largeTitle)
            .foregroundColor(.white)
            .padding()
            .opacity(uiStateMachine.state.canAddPerson ? 1 : 0.5)
            .disabled(!uiStateMachine.state.canAddPerson)
          }
          .padding()

          Spacer()

          HStack {
            Spacer()

            Button {
              uiStateMachine.send(DidRequestToOpen())
            } label: {
              Text("Open")
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 5)
            .opacity(uiStateMachine.state.canPressOpen ? 1 : 0.5)
            .disabled(!uiStateMachine.state.canPressOpen)

            Spacer()

            Button {
              uiStateMachine.send(DidRequestToClose())
            } label: {
              Text("Close")
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 5)
            .opacity(uiStateMachine.state.canPressClose ? 1 : 0.5)
            .disabled(!uiStateMachine.state.canPressClose)

            Spacer()
          }

          Spacer()
        }
        .background(Color.pink)
        .clipShape(
          RoundedRectangle(
            cornerRadius: 20,
            style: .continuous
          )
        )
        .shadow(radius: 10)
        .padding()

        VStack {
          Spacer()
          HStack {
            Spacer()
            Image(systemName: uiStateMachine.state.symbol)
              .font(.system(size: 120))

            Spacer()
          }
          .padding()

          Text(uiStateMachine.state.message)
          Spacer()
        }
        .padding()
      }
    }
    .navigationTitle(Text("Elevator"))
  }

  // MARK: Private

  @Environment(\.elevatorStateMachineFactory) private var stateMachineFactory
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
      .environment(\.elevatorStateMachineFactory, .default(initial: ElevatorIsOpen(persons: 2)))
      .previewDisplayName("Elevator is open")

    RootView()
      .environment(\.elevatorStateMachineFactory, .default(initial: ElevatorIsClosed(persons: 3)))
      .previewDisplayName("Elevator is closed")

    RootView()
      .environment(\.elevatorStateMachineFactory, .default(initial: ElevatorIsInWarning(persons: 7)))
      .previewDisplayName("Elevator is in warning")
  }
}
