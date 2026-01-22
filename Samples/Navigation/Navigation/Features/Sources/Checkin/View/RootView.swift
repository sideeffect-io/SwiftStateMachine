import CheckinDomain
import CheckinStateMachine
import OwnerView
import PlacesView
import PlaceView
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
      NavigationStack(path: uiStateMachine.binding(\.routes, send: { DidRequestResettingRoutes(routes: $0) })) {
        PlacesView.RootView()
          .navigationDestination(for: Route.self) { route in
            switch route {
            case .place(let id): PlaceView.RootView(placeId: id)
            case .owner(let id): OwnerView.RootView(ownerId: id)
            }
          }
      }
      .onOpenURL { url in
        uiStateMachine.send(DidReceiveDeepLink(url: url))
      }
    }
  }

  // MARK: Private

  @Environment(\.checkinStateMachineFactory) private var stateMachineFactory

}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
      .environment(
        \.checkinStateMachineFactory,
        .default(initial: CheckinState(routes: [Route.place(id: "1")]))
      )
  }
}
