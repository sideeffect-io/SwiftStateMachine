import AlbumsDomain
import AlbumsStateMachine
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
      ZStack {
        List(uiStateMachine.state.albums) { album in
          Button {
            uiStateMachine.send(DidSelectAlbum(albumId: album.id))
          } label: {
            VStack(alignment: .leading) {
              Text(album.title)
                .font(.title3)

              HStack {
                Text(album.author)
                Text("-")
                Text("\(album.numberOfSongs) songs")
                Spacer()
              }
              .font(.caption)
            }
          }
        }
        .refreshable {
          await uiStateMachine.sendAndWait(DidRequestLoading(isFullLoading: false))
        }

        if uiStateMachine.state.isLoading {
          Color.black
            .edgesIgnoringSafeArea(.all)
            .opacity(0.2)

          ProgressView()
        }

        if uiStateMachine.state.isFailed {
          Text("An error has occured, refresh the list.")
        }
      }
      .onAppear {
        uiStateMachine.send(DidRequestLoading(isFullLoading: true))
      }
    }
    .navigationTitle(Text("Albums"))
  }

  // MARK: Private

  @Environment(\.albumsStateMachineFactory) private var stateMachineFactory
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
      .environment(\.albumsStateMachineFactory, .default(initial: AlbumsAreIdle()))
      .previewDisplayName("AlbumsAreIdle")

    RootView()
      .environment(\.albumsStateMachineFactory, .default(initial: AlbumsAreLoading(previous: [])))
      .previewDisplayName("AlbumsAreLoading empty")

    RootView()
      .environment(\.albumsStateMachineFactory, .default(initial: AlbumsAreLoading(previous: [.fake, .fake])))
      .previewDisplayName("AlbumsAreLoading previous")

    RootView()
      .environment(\.albumsStateMachineFactory, .default(initial: AlbumsAreLoaded(albums: [.fake, .fake])))
      .previewDisplayName("AlbumsAreLoaded")

    RootView()
      .environment(\.albumsStateMachineFactory, .default(initial: AlbumsAreInFailure()))
      .previewDisplayName("AlbumsAreInFailure")
  }
}
