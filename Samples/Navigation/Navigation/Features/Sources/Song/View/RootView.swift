import Common
import SongDomain
import SongStateMachine
import StateMachineCore
import SwiftUI

// MARK: - RootView

public struct RootView: View {

  // MARK: - Lifecycle

  // MARK: Public

  public init(songId: String) {
    self.songId = songId
  }

  // MARK: - Properties

  // MARK: Public

  public var body: some View {
    StateMachineView(factory: stateMachineFactory) { uiStateMachine in
      VStack(alignment: .trailing) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 30)
        }
        .padding()

        ZStack {
          List {
            Label(uiStateMachine.state.song.title, systemImage: "music.mic.circle.fill")
            Label(uiStateMachine.state.song.author, systemImage: "person.fill")
            Label(uiStateMachine.state.song.duration, systemImage: "clock.fill")
          }
          .listStyle(.plain)
          .redacted(when: uiStateMachine.state.isLoading)

          if uiStateMachine.state.isLoading {
            Color.black
              .edgesIgnoringSafeArea(.all)
              .opacity(0.2)

            ProgressView()
          }
        }
      }
      .task {
        // initial loading
        uiStateMachine.send(DidRequestLoading(songId: songId))
      }
      .onChange(of: songId) { newId in
        // reloading when the songId change "in place" because of a deep link
        // while we are already displaying this screen.
        uiStateMachine.send(DidRequestLoading(songId: newId))
      }
    }
  }

  // MARK: Private

  @Environment(\.songStateMachineFactory) private var stateMachineFactory
  @Environment(\.dismiss) private var dismiss

  private let songId: String
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView(songId: "")
      .environment(\.songStateMachineFactory, .default(initial: SongIsIdle()))
      .previewDisplayName("SongIsIdle")

    RootView(songId: "1")
      .environment(\.songStateMachineFactory, .default(initial: SongIsLoading()))
      .previewDisplayName("SongIsLoading")

    RootView(songId: "1")
      .environment(\.songStateMachineFactory, .default(initial: SongIsLoaded(song: .fake)))
      .previewDisplayName("SongIsLoaded")
  }
}
