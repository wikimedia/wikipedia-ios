// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WMFTestKitchen",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WMFTestKitchen",
            targets: ["WMFTestKitchen"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WMFTestKitchen"),
        .testTarget(
            name: "WMFTestKitchenTests",
            dependencies: ["WMFTestKitchen"]
        )
    ],
    // Swift 6 language mode. The compiler enforces data-race safety as errors.
    swiftLanguageModes: [.v6]
)
