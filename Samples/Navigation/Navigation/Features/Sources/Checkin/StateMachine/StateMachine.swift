import CheckinDomain
import StateMachineCore
import SwiftUI

public let asyncStateMachine = AsyncStateMachine<CheckinState, CheckinEvent>(
  initial: CheckinState(routes: [])
) {
  When(state: CheckinState.self) {
    On(event: DidRequestResettingRoutes.self) { _, event in
      Transition(state: CheckinState(routes: event.routes))
    }

    On(event: DidRequestAddingRoutes.self) { state, event in
      Transition(state: CheckinState(routes: state.routes + event.routes))
    }

    On(event: DidReceiveDeepLink.self, guard: { isDeepLinkIsForCheckin(event: $1) }) { _, event in
      Transition(state: CheckinState(routes: computeRoutes(from: event.url)))
    }

    On(event: DidReceiveDeepLink.self, guard: { !isDeepLinkIsForCheckin(event: $1) }) { _, _ in
      Transition(state: CheckinState(routes: []))
    }
  }
}

@Sendable
func isDeepLinkIsForCheckin(event: DidReceiveDeepLink) -> Bool {
  guard event.url.scheme == "poc" else { return false }
  guard event.url.host == "checkin" else { return false }
  return true
}

@Sendable
func computeRoutes(from url: URL) -> [Route] {
  let components = url.path().split(separator: "/")
  if components.count == 2 {
    let placeId = components[1]
    return [
      .place(id: "\(placeId)")
    ]
  } else if components.count == 4 {
    let placeId = components[1]
    let ownerId = components[3]
    return [
      .place(id: "\(placeId)"),
      .owner(id: "\(ownerId)")
    ]
  }
  return []
}
