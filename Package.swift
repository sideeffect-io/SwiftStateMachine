// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let debugConcurrencySettings: [SwiftSetting] = [
  .unsafeFlags([
    "-Xfrontend", "-warn-concurrency",
    "-Xfrontend", "-enable-actor-data-race-checks",
  ], .when(configuration: .debug))
]

let package = Package(
  name: "StateMachine",
  platforms: [
    .iOS(.v16),
    .macOS(.v13)
  ],
  products: [
    .library(
      name: "StateMachine",
      targets: [
        "StateMachineBroadcast",
        "StateMachineCore",
        "StateMachineDump",
        "StateMachineTest"
      ]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git", exact: "1.4.2"),
    .package(url: "https://github.com/apple/swift-collections.git", exact: "1.1.4")
  ],
  targets: [
    // Enable strict concurrency diagnostics in Debug to surface Sendable and isolation issues early.
    // Keep Release clean for distribution until the public API is fully audited.
    .target(
      name: "StateMachineShared",
      dependencies: [
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
      ],
      path: "Sources/Shared",
      swiftSettings: debugConcurrencySettings
    ),
    .target(
      name: "StateMachineCore",
      dependencies: [
        .product(name: "Collections", package: "swift-collections"),
        "StateMachineShared"
      ],
      path: "Sources/Core",
      swiftSettings: debugConcurrencySettings
    ),
    .target(
      name: "StateMachineBroadcast",
      dependencies: [
        "StateMachineCore"
      ],
      path: "Sources/Broadcast",
      swiftSettings: debugConcurrencySettings
    ),
    .target(
      name: "StateMachineDump",
      dependencies: [
        .product(name: "Collections", package: "swift-collections"),
        "StateMachineCore"
      ],
      path: "Sources/Dump",
      swiftSettings: debugConcurrencySettings
    ),
    .target(
      name: "StateMachineTest",
      dependencies: [
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
        "StateMachineCore",
        "StateMachineShared"
      ],
      path: "Sources/Test",
      swiftSettings: debugConcurrencySettings
    ),
    .testTarget(
      name: "StateMachineTests",
      dependencies: [
        "StateMachineBroadcast",
        "StateMachineCore",
        "StateMachineDump",
        "StateMachineShared",
        "StateMachineTest"
      ],
      path: "Tests",
      swiftSettings: debugConcurrencySettings
    )
  ]
)
