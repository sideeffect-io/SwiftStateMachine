// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Implementations",
  platforms: [
    .iOS(.v16)
  ],
  products: [
    .library(
      name: "Api",
      targets: ["Api"]
    ),

    .library(
      name: "FileSystem",
      targets: ["FileSystem"]
    )
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "Api",
      dependencies: [],
      path: "Sources/Api"
    ),

    .target(
      name: "FileSystem",
      dependencies: [],
      path: "Sources/FileSystem"
    )
  ]
)
