# Structure of the project
* **Implementations**: This local package provides all the concrete implementations (API fetching, filesystem access, ...). Each tech layer is its own self contained library.
* **Features**: This local package provides the implementations of all the features. Each feature is its own self contained library. It can be built in isolation and does not depend on concrete implementations.
* **The app**: This is the application entry point. It imports both the **Features** and the **Implementations** packages. Its goal is to build and inject the features's concrete dependencies and acts as an adapter between the concrete implementations and what's expected by each feature.

# Navigation
As of now, there are 2 levels of navigation:

* the tab bar handled by the **Home** feature
* the navigation stack in the checkin tab handled by the **Checkin** feature

## Tab bar: Home

The tab bar is a `TabView` component. As this component relies on a `Binding` on the selected tab, we use a state machine to keep track of this selection as a state and we derive a `Binding` from it. Doing so, it is possible to update it from anywhere in the code as long as you have access to the state machine.

## Navigation stack: Checkin 

The checkin navigation stack is a `NavigationStack` component. As this component relies on a `Binding` on a collection of `Route`, we use a state machine to keep track of this collection and we derive a `Binding` from it. Doing so, it is possible to update it from anywhere in the code as long as you have access to the state machine. For instance when selecting a place from the **places** screen, the **places** state machine is set to a `Picked` state. From there a mediator is triggered and sends an `AddToRoutes(route: .place(id: x))` event into the **Checkin** state machine. As a consequence, the `CheckinView` is refreshed and the `NavigationStack` executes the `navigationDestination(_:)` modifier to compute the next view to stack. This has the benefit of a total decoupling between the root view (the coordinator) and its children.

When the **Back** button is pressed, the binding on the path is set to a new value that triggers a `SetRoutes(_:)` event into the **Checkin** state machine. As the path is changed, the `NavigationStack` refreshes accordingly. 

## Navigation stack: Music 

The music navigation stack is a `NavigationStack` component. The component is used in a similar way as in the **Checkin** flow. The difference
is that there is only one level of navigation in the stack: **albums -> album** and from the album screen we can ask to display a song in a `sheet`.
All the navigation for this flow (including displaying the `sheet`) is handled by the top level view `MusicView`, in the same way a coordinator pattern would do.


# Deep linking

Handling the navigation thanks to state machines enables a full control on the application flow, especially for the deep links.

## Tab bar: Home

When the `onOpenURL(_:)` is called on the `HomeView`, a `ProcessDeeplink(_:)` event is sent into the **Home** state machine. This event triggers a transition where the URL is analysed and the tab id is extracted. A new `HomeState` is computed and the binding is updated. As a consequence the `TabView` is refreshed and selects the tab id from the state.

You can try these commands in your terminal to trigger a deep link that changes the selected tab:

```
// Profile tab
xcrun simctl openurl booted "poc://profile”

// Music tab
xcrun simctl openurl booted "poc://music”

// Checkin tab -> places screen
xcrun simctl openurl booted "poc://checkin"
```

## Navigation stack: Checkin

When the `onOpenURL(_:)` is called on the `CheckinView`, a `ProcessDeeplink(_:)` event is sent into the **Checkin** state machine. This event triggers a transition where the URL is analysed and the data is extracted (selected place, selected owner). A new `CheckinState` is computed with the navigation path and the binding is updated. As a consequence the `NavigationStack` is refreshed and uses the `navigationDestination(_:)` modifier to stack the expected screens.

You can try these commands in your terminal to trigger a deep link that changes the screens in the Checkin navigation stack:

```
// Checkin tab -> places screen -> place "3" screen
xcrun simctl openurl booted "poc://checkin/place/3"

// Checkin tab -> places screen -> place "3" screen -> owner "5" screen
xcrun simctl openurl booted "poc://checkin/place/3/owner/5"
```

## Navigation stack: Music

When the `onOpenURL(_:)` is called on the `MusicView`, a `ProcessDeeplink(_:)` event is sent into the **Music** state machine.
This event triggers a transition where the URL is analysed and the data is extracted (selected album, selected song).
A new `MusicState` is computed with the new routes and the popup. This new state is interpreted by `MusicView` and 
the destination + sheet are refreshed accordingly.

You can try these commands in your terminal to trigger a deep link that changes the screens in the Music navigation stack:

```
// Music tab -> albums screen -> album "3" screen
xcrun simctl openurl booted "poc://music/album/3"

// Music tab -> albums screen -> album "3" screen -> song "5" screen
xcrun simctl openurl booted "poc://music/album/1/song/5"
```
