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
      name: "Features",
      targets: ["Clics", "Counter", "Elevator", "Analysis", "Wallet"]
    )
  ],
  dependencies: [.package(name: "StateMachine", path: "../../../../")],
  targets: [
    // CLICS
    .target(
      name: "Clics",
      dependencies: ["StateMachine"]
    ),
    .testTarget(
      name: "ClicsTests",
      dependencies: ["Clics"]
    ),

    // COUNTER
    .target(
      name: "Counter",
      dependencies: ["StateMachine"]
    ),
    .testTarget(
      name: "CounterTests",
      dependencies: ["Counter"]
    ),

    // ELEVATOR
    .target(
      name: "Elevator",
      dependencies: ["StateMachine"]
    ),
    .testTarget(
      name: "ElevatorTests",
      dependencies: ["Elevator"]
    ),

    // ANALYSIS
    .target(
      name: "Analysis",
      dependencies: ["StateMachine"]
    ),
    .testTarget(
      name: "AnalysisTests",
      dependencies: ["Analysis"]
    ),

    // WALLET
    .target(
      name: "Wallet",
      dependencies: ["StateMachine"]
    ),
    .testTarget(
      name: "WalletTests",
      dependencies: ["Wallet"]
    )
  ]
)
