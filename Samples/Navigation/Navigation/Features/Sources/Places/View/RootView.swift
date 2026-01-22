import PlacesStateMachine
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
    StateMachineView(factory: stateMachineFactory, mapping: toViewState(state:)) { uiStateMachine in
      ZStack {
        List(uiStateMachine.state.places) { viewPlace in
          Button {
            uiStateMachine.send(DidSelectPlace(id: viewPlace.id))
          } label: {
            HStack {
              Text(viewPlace.place.name)

              Spacer()
              ForEach(viewPlace.stars) { star in
                Image(systemName: star.image)
                  .renderingMode(.original)
              }
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
      }
      .onAppear {
        uiStateMachine.send(DidRequestLoading(isFullLoading: true))
      }
    }
    .navigationTitle(Text("Places"))
  }

  // MARK: Private

  @Environment(\.placesStateMachineFactory) private var stateMachineFactory
}

// MARK: - RootView_Previews

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    RootView()
      .environment(\.placesStateMachineFactory, .default(initial: PlacesAreIdle()))
      .previewDisplayName("PlacesAreIdle")

    RootView()
      .environment(\.placesStateMachineFactory, .default(initial: PlacesAreLoading(previous: [])))
      .previewDisplayName("PlacesAreLoading empty")

    RootView()
      .environment(\.placesStateMachineFactory, .default(initial: PlacesAreLoading(previous: [.fake, .fake])))
      .previewDisplayName("PlacesAreLoading previous")

    RootView()
      .environment(\.placesStateMachineFactory, .default(initial: PlacesAreLoaded(places: [.fake, .fake])))
      .previewDisplayName("PlacesAreLoaded")

    RootView()
      .environment(
        \.placesStateMachineFactory,
        .default(initial: PlaceIsSelected(places: [.fake, .fake], placeId: "1"))
      )
      .previewDisplayName("PlaceIsSelected")
  }
}
