import CheckinView
import HomeDomain
import HomeStateMachine
import MusicView
import ProfileView
import StateMachineCore
import StateMachineDump
import SwiftUI

// MARK: - RootView

public struct RootView: View {
  // MARK: - Lifecycle

  // MARK: Public

  public init() { }

  // MARK: - Properties

  // MARK: Public

  public var body: some View {
    TabView(selection: uiStateMachine.binding(get: { $0.section }, send: { DidSelectSection(section: $0) })) {
      CheckinView.RootView()
        .tabItem {
          Label("Checkin", systemImage: "mappin.and.ellipse")
        }
        .tag(Section.checkin)

      MusicView.RootView()
        .tabItem {
          Label("Music", systemImage: "music.note")
        }
        .tag(Section.music)

      ProfileView.RootView()
        .tabItem {
          Label("Profile", systemImage: "person.crop.circle")
        }
        .tag(Section.profile)
    }
    .onOpenURL { url in
      uiStateMachine.send(DidReceiveDeepLink(url: url))
    }
    .task {
      uiStateMachine.start()
    }
  }

  // MARK: Private

  @StateObject private var uiStateMachine = UIStateMachine(
    asyncStateMachine: asyncStateMachine
    #if DEBUG
      .activateDump()
    #endif
  )
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
  }
}
