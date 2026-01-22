// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Features",
  platforms: [
    .iOS(.v16)
  ],
  products: [
    .library(
      name: "Album",
      targets: ["AlbumView"]
    ),

    .library(
      name: "Albums",
      targets: ["AlbumsView"]
    ),

    .library(
      name: "Checkin",
      targets: ["CheckinView"]
    ),

    .library(
      name: "Home",
      targets: ["HomeView"]
    ),

    .library(
      name: "Music",
      targets: ["MusicView"]
    ),

    .library(
      name: "Owner",
      targets: ["OwnerView"]
    ),

    .library(
      name: "Place",
      targets: ["PlaceView"]
    ),

    .library(
      name: "Places",
      targets: ["PlacesView"]
    ),

    .library(
      name: "Profile",
      targets: ["ProfileView"]
    ),

    .library(
      name: "Song",
      targets: ["SongView"]
    )
  ],
  dependencies: [.package(name: "StateMachine", path: "../../../../")],
  targets: [
    // ////////////
    //  Tab Home //
    // ////////////

    .target(
      name: "HomeView",
      dependencies: ["HomeStateMachine", "HomeDomain", "CheckinView", "MusicView", "ProfileView", "StateMachine"],
      path: "Sources/Home/View"
    ),

    .target(
      name: "HomeStateMachine",
      dependencies: ["HomeDomain", "StateMachine"],
      path: "Sources/Home/StateMachine"
    ),

    .target(
      name: "HomeDomain",
      dependencies: [],
      path: "Sources/Home/Domain"
    ),

    // /////////////////
    //  Stack Checkin //
    // /////////////////

    .target(
      name: "CheckinView",
      dependencies: ["CheckinStateMachine", "CheckinDomain", "OwnerView", "PlacesView", "PlaceView", "StateMachine"],
      path: "Sources/Checkin/View"
    ),

    .target(
      name: "CheckinStateMachine",
      dependencies: ["CheckinDomain", "StateMachine"],
      path: "Sources/Checkin/StateMachine"
    ),

    .target(
      name: "CheckinDomain",
      dependencies: [],
      path: "Sources/Checkin/Domain"
    ),

    // /////////////////
    //  Screen Places //
    // /////////////////

    .target(
      name: "PlacesView",
      dependencies: ["PlacesStateMachine", "PlacesDomain", "StateMachine"],
      path: "Sources/Places/View"
    ),

    .target(
      name: "PlacesStateMachine",
      dependencies: ["PlacesDomain", "StateMachine"],
      path: "Sources/Places/StateMachine"
    ),

    .target(
      name: "PlacesDomain",
      dependencies: [],
      path: "Sources/Places/Domain"
    ),

    // /////////////////
    //  Screen Place ///
    // /////////////////

    .target(
      name: "PlaceView",
      dependencies: ["PlaceDomain", "PlaceStateMachine", "StateMachine", "Common"],
      path: "Sources/Place/View"
    ),

    .target(
      name: "PlaceStateMachine",
      dependencies: ["PlaceDomain", "StateMachine"],
      path: "Sources/Place/StateMachine"
    ),

    .target(
      name: "PlaceDomain",
      dependencies: [],
      path: "Sources/Place/Domain"
    ),

    // /////////////////
    //  Screen Owner ///
    // /////////////////

    .target(
      name: "OwnerView",
      dependencies: ["OwnerDomain", "OwnerStateMachine", "StateMachine", "Common"],
      path: "Sources/Owner/View"
    ),

    .target(
      name: "OwnerStateMachine",
      dependencies: ["OwnerDomain", "StateMachine"],
      path: "Sources/Owner/StateMachine"
    ),

    .target(
      name: "OwnerDomain",
      dependencies: [],
      path: "Sources/Owner/Domain"
    ),

    // //////////////
    // Stack Music //
    // //////////////

    .target(
      name: "MusicView",
      dependencies: ["MusicDomain", "MusicStateMachine", "AlbumsView", "AlbumView", "SongView", "StateMachine"],
      path: "Sources/Music/View"
    ),

    .target(
      name: "MusicStateMachine",
      dependencies: ["MusicDomain", "StateMachine"],
      path: "Sources/Music/StateMachine"
    ),

    .target(
      name: "MusicDomain",
      dependencies: [],
      path: "Sources/Music/Domain"
    ),

    // ////////////////
    // Screen albums //
    // ////////////////

    .target(
      name: "AlbumsView",
      dependencies: ["AlbumsDomain", "AlbumsStateMachine", "StateMachine"],
      path: "Sources/Albums/View"
    ),

    .target(
      name: "AlbumsStateMachine",
      dependencies: ["AlbumsDomain", "StateMachine"],
      path: "Sources/Albums/StateMachine"
    ),

    .target(
      name: "AlbumsDomain",
      dependencies: [],
      path: "Sources/Albums/Domain"
    ),

    // ////////////////
    // Screen album //
    // ////////////////

    .target(
      name: "AlbumView",
      dependencies: ["AlbumDomain", "AlbumStateMachine", "StateMachine", "Common"],
      path: "Sources/Album/View"
    ),

    .target(
      name: "AlbumStateMachine",
      dependencies: ["AlbumDomain", "StateMachine"],
      path: "Sources/Album/StateMachine"
    ),

    .target(
      name: "AlbumDomain",
      dependencies: [],
      path: "Sources/Album/Domain"
    ),

    // ////////////////
    // Screen song //
    // ////////////////

    .target(
      name: "SongView",
      dependencies: ["SongDomain", "SongStateMachine", "StateMachine", "Common"],
      path: "Sources/Song/View"
    ),

    .target(
      name: "SongStateMachine",
      dependencies: ["SongDomain", "StateMachine"],
      path: "Sources/Song/StateMachine"
    ),

    .target(
      name: "SongDomain",
      dependencies: [],
      path: "Sources/Song/Domain"
    ),

    // ///////////////
    //  Tab Profile //
    // ///////////////

    .target(
      name: "ProfileView",
      dependencies: ["ProfileStateMachine", "StateMachine"],
      path: "Sources/Profile/View"
    ),

    .target(
      name: "ProfileStateMachine",
      dependencies: ["StateMachine"],
      path: "Sources/Profile/StateMachine"
    ),

    // ///////////
    //  Common ///
    // ///////////

    .target(
      name: "Common",
      dependencies: [],
      path: "Sources/Common"
    )
  ]
)
