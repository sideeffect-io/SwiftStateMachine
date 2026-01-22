import Foundation
import HomeDomain
import StateMachineCore

public let asyncStateMachine = AsyncStateMachine<HomeState, HomeEvent>(
  initial: HomeState(section: .checkin)
) {
  When(state: HomeState.self) {
    On(event: DidSelectSection.self) { _, event in
      Transition(state: HomeState(section: event.section))
    }

    On(event: DidReceiveDeepLink.self, guard: isDeepLinkIsForHome) { _, event in
      Transition(state: HomeState(section: computeSection(from: event.url)))
    }
  }
}

@Sendable
func isDeepLinkIsForHome(state _: any State<HomeState>, event: DidReceiveDeepLink) -> Bool {
  event.url.scheme == "poc"
}

@Sendable
func computeSection(from url: URL) -> Section {
  switch url.host {
  case "checkin": .checkin
  case "music": .music
  case "profile": .profile
  default: .checkin
  }
}
