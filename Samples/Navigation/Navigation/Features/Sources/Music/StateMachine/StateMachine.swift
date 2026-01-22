import AlbumsDomain
import MusicDomain
import StateMachineCore
import SwiftUI

public let asyncStateMachine = AsyncStateMachine<MusicState, MusicEvent>(
  initial: MusicState(routes: [])
) {
  When(state: MusicState.self) {
    On(event: DidRequestResettingRoutes.self) { state, event in
      Transition(state: MusicState(routes: event.routes, popup: state.popup))
    }

    On(event: DidRequestSettingPopup.self) { state, event in
      Transition(state: MusicState(routes: state.routes, popup: event.popup))
    }

    On(event: DidRequestResettingPopup.self) { state, _ in
      Transition(state: MusicState(routes: state.routes, popup: nil))
    }

    On(event: DidRequestAddingRoutes.self) { state, event in
      Transition(state: MusicState(routes: state.routes + event.routes, popup: state.popup))
    }

    On(event: DidReceiveDeepLink.self, guard: { isDeepLinkIsForCheckin(event: $1) }) { _, event in
      Transition {
        let destinations = computeDestinations(from: event.url)
        return MusicState(routes: destinations.routes, popup: destinations.popup)
      }
    }

    On(event: DidReceiveDeepLink.self, guard: { !isDeepLinkIsForCheckin(event: $1) }) { _, _ in
      Transition(state: MusicState(routes: [], popup: nil))
    }
  }
}

@Sendable
func isDeepLinkIsForCheckin(event: DidReceiveDeepLink) -> Bool {
  guard event.url.scheme == "poc" else { return false }
  guard event.url.host == "music" else { return false }
  return true
}

@Sendable
func computeDestinations(from url: URL) -> (routes: [Route], popup: Popup?) {
  let components = url.path().split(separator: "/")
  if components.count == 2 {
    let albumId = components[1]
    return (routes: [Route.album(id: "\(albumId)")], popup: nil)
  } else if components.count == 4 {
    let albumId = components[1]
    let songId = components[3]
    return (routes: [Route.album(id: "\(albumId)")], popup: Popup.song(id: "\(songId)"))
  }
  return ([], nil)
}
