import Common
import OwnerDomain
import OwnerStateMachine
import StateMachineCore
import SwiftUI

// MARK: - RootView

public struct RootView: View {

  // MARK: - Lifecycle

  // MARK: Public

  public init(ownerId: String) {
    self.ownerId = ownerId
  }

  // MARK: - Properties

  // MARK: Public

  public var body: some View {
    StateMachineView(factory: stateMachineFactory) { uiStateMachine in
      ZStack {
        Form {
          Label(uiStateMachine.state.owner.name, systemImage: "person.crop.circle.fill")
          Label(uiStateMachine.state.owner.address, systemImage: "map.circle.fill")
          Label("\(uiStateMachine.state.owner.age)", systemImage: "calendar.circle.fill")
        }
        .redacted(when: uiStateMachine.state.isLoading)

        if uiStateMachine.state.isLoading {
          Color.black
            .edgesIgnoringSafeArea(.all)
            .opacity(0.2)

          ProgressView()
        }
      }
      .onAppear {
        uiStateMachine.send(DidRequestLoading(id: ownerId))
      }
      .onChange(of: ownerId) { newId in
        // reloading when the ownerId change "in place" because of a deep link
        // while we are already displaying this screen.
        uiStateMachine.send(DidRequestLoading(id: newId))
      }
    }
  }

  // MARK: Private

  @Environment(\.ownerStateMachineFactory) private var stateMachineFactory
  private let ownerId: String
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView(ownerId: "")
      .environment(\.ownerStateMachineFactory, .default(initial: OwnerIsIdle()))
      .previewDisplayName("OwnerIsIdle")

    RootView(ownerId: "1")
      .environment(\.ownerStateMachineFactory, .default(initial: OwnerIsLoading()))
      .previewDisplayName("OwnerIsLoading")

    RootView(ownerId: "1")
      .environment(\.ownerStateMachineFactory, .default(initial: OwnerIsLoaded(owner: .fake)))
      .previewDisplayName("OwnerIsLoaded")
  }
}
