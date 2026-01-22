import Common
import PlaceStateMachine
import StateMachineCore
import SwiftUI

// MARK: - RootView

public struct RootView: View {
  // MARK: - Lifecycle

  // MARK: Public

  public init(placeId: String) {
    self.placeId = placeId
  }

  // MARK: - Properties

  // MARK: Public

  public var body: some View {
    StateMachineView(factory: stateMachineFactory) { uiStateMachine in
      ZStack {
        if uiStateMachine.state.isError {
          Text("An error has occured!")
        } else {
          Form {
            Label(uiStateMachine.state.place.name, systemImage: "house.circle.fill")
            Label(uiStateMachine.state.place.address, systemImage: "map.circle.fill")
            Label(uiStateMachine.state.place.telephone, systemImage: "phone.circle.fill")
            Label(uiStateMachine.state.place.description, systemImage: "info.circle.fill")
            Button {
              uiStateMachine.send(DidSelectOwner(id: uiStateMachine.state.place.owner.id))
            } label: {
              Label(uiStateMachine.state.place.owner.name, systemImage: "person.circle.fill")
            }
          }
          .redacted(when: uiStateMachine.state.isLoading)

          if uiStateMachine.state.isLoading {
            Color.black
              .edgesIgnoringSafeArea(.all)
              .opacity(0.2)

            ProgressView()
          }
        }
      }
      .onAppear {
        uiStateMachine.send(DidRequestLoading(id: placeId))
      }
      .onChange(of: placeId) { newId in
        // reloading when the placeId change "in place" because of a deep link
        // while we are already displaying this screen.
        uiStateMachine.send(DidRequestLoading(id: newId))
      }
    }
  }

  // MARK: Private

  @Environment(\.placeStateMachineFactory) private var stateMachineFactory
  private let placeId: String
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView(placeId: "")
      .environment(\.placeStateMachineFactory, .default(initial: PlaceIsIdle()))
      .previewDisplayName("PlaceIsIdle")

    RootView(placeId: "1")
      .environment(\.placeStateMachineFactory, .default(initial: PlaceIsLoading()))
      .previewDisplayName("PlaceIsLoading")

    RootView(placeId: "1")
      .environment(\.placeStateMachineFactory, .default(initial: PlaceIsLoaded(place: .fake)))
      .previewDisplayName("PlaceIsLoaded")

    RootView(placeId: "1")
      .environment(\.placeStateMachineFactory, .default(initial: OwnerIsSelected(place: .fake, ownerId: "1")))
      .previewDisplayName("OwnerIsSelected")

    RootView(placeId: "1")
      .environment(\.placeStateMachineFactory, .default(initial: PlaceIsInFailure()))
      .previewDisplayName("PlaceIsAFailure")
  }
}
