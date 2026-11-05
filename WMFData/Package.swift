// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WMFData",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "WMFData",
            targets: ["WMFData"]),
        .library(name: "WMFDataMocks",
            targets: ["WMFDataMocks"]),
        .library(name: "WMFDataTestSupport",
            targets: ["WMFDataTestSupport"])
    ],
    dependencies: [
        .package(name: "WMFTestKitchen", path: "../WMFTestKitchen/")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "WMFData",
            dependencies: [
                .product(name: "WMFTestKitchen", package: "WMFTestKitchen")
            ],
            path: "Sources/WMFData",
            resources: [.process("Resources")]),
        .target(name: "WMFDataMocks",
            dependencies: ["WMFData"],
            path: "Sources/WMFDataMocks",
            resources: [.process("Resources")]),
        .target(name: "WMFDataTestSupport",
            dependencies: ["WMFData"],
            path: "Sources/WMFDataTestSupport"),
        .testTarget(
            name: "WMFDataTests",
            dependencies: ["WMFData", "WMFDataMocks", "WMFDataTestSupport"])
    ],
    // Swift 6 language mode. The compiler enforces data-race safety as errors.
    swiftLanguageModes: [.v6]
)
