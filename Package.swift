// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "MacMenuBarPop",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "MacMenuBarPop", targets: ["MacMenuBarPop"]),
  ],
  targets: [
    .executableTarget(
      name: "MacMenuBarPop",
      path: "Sources/MacMenuBarPop"
    ),
  ]
)
