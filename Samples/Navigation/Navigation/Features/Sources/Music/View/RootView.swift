import AlbumsView
import AlbumView
import MusicDomain
import MusicStateMachine
import SongView
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
        AlbumsView.RootView()
          .navigationDestination(for: Route.self) { route in
            switch route {
            case .album(let id):
              AlbumView.RootView(albumId: id)
            }
          }
      }
      .sheet(item: uiStateMachine.binding(\.popup, send: DidRequestResettingPopup())) { popup in
        switch popup {
        case .song(let id):
          SongView.RootView(songId: id)
        }
      }
      .onOpenURL { url in
        uiStateMachine.send(DidReceiveDeepLink(url: url))
      }
    }
  }

  // MARK: Private

  @Environment(\.musicStateMachineFactory) private var stateMachineFactory
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
      .environment(
        \.musicStateMachineFactory,
        .default(initial: MusicState(routes: [Route.album(id: "1")]))
      )
  }
}
