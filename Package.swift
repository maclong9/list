// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "sls",
  products: [
    .executable(name: "sls", targets: ["sls"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
  ],
  targets: [
    .executableTarget(
      name: "sls",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ]
    ),
    .testTarget(
      name: "SwiftListTests",
      dependencies: ["sls"]
    ),
  ]
)
