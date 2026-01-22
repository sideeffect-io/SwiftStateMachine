import AlbumDomain
import AlbumStateMachine
import Common
import StateMachineCore
import SwiftUI

// MARK: - RootView

public struct RootView: View {
  // MARK: - Lifecycle

  // MARK: Public

  public init(albumId: String) {
    self.albumId = albumId
  }

  // MARK: - Properties

  // MARK: Public

  public var body: some View {
    StateMachineView(factory: stateMachineFactory) { uiStateMachine in
      ZStack {
        if uiStateMachine.state.isError {
          Text("An error has occured!")
        } else {
          VStack {
            Form {
              LabeledContent("Title", value: uiStateMachine.state.album.title)
              LabeledContent("Author", value: uiStateMachine.state.album.author)
              LabeledContent("Producer", value: uiStateMachine.state.album.producer)
              LabeledContent("Released", value: uiStateMachine.state.album.dateOfRelease)

              Section("Songs") {
                List(uiStateMachine.state.album.songs) { song in
                  Button {
                    uiStateMachine.send(DidSelectSong(songId: song.id))
                  } label: {
                    Text(song.title)
                  }
                }
              }
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
      .task {
        // initial loading
        uiStateMachine.send(DidRequestLoading(albumId: albumId))
      }
      .onChange(of: albumId) { newId in
        // reloading when the albumId change "in place" because of a deep link
        // while we are already displaying this screen.
        uiStateMachine.send(DidRequestLoading(albumId: newId))
      }
    }
  }

  // MARK: Private

  @Environment(\.albumStateMachineFactory) private var stateMachineFactory
  private let albumId: String
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView(albumId: "1")
      .environment(\.albumStateMachineFactory, .default(initial: AlbumIsIdle()))
      .previewDisplayName("AlbumIsIdle")

    RootView(albumId: "1")
      .environment(\.albumStateMachineFactory, .default(initial: AlbumIsLoading()))
      .previewDisplayName("AlbumIsLoading")

    RootView(albumId: "1")
      .environment(\.albumStateMachineFactory, .default(initial: AlbumIsLoaded(album: .fake)))
      .previewDisplayName("AlbumIsLoaded")

    RootView(albumId: "1")
      .environment(\.albumStateMachineFactory, .default(initial: SongIsSelected(album: .fake, songId: "1")))
      .previewDisplayName("SongIsSelected")

    RootView(albumId: "1")
      .environment(\.albumStateMachineFactory, .default(initial: AlbumIsInFailure()))
      .previewDisplayName("AlbumIsInFailure")
  }
}
