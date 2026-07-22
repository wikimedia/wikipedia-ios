// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WMFComponents",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "WMFComponents",
            targets: ["WMFComponents"])
    ],
    dependencies: [
        .package(name: "WMFData", path: "../WMFData/"),
        .package(name: "WMFLocalizations", path: "../WMFLocalizations/"),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.19.0"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.5.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "WMFComponents",
            dependencies: [
                .product(name: "WMFData", package: "WMFData"),
                .product(name: "WMFDataMocks", package: "WMFData"),
                .product(name: "SDWebImage", package: "SDWebImage"),
                .product(name: "Lottie", package: "lottie-ios"),
                .product(name: "WMFNativeLocalizations", package: "WMFLocalizations")
            ],
            path: "Sources/WMFComponents",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "WMFComponentsTests",
            dependencies: ["WMFComponents",
                           .product(name: "WMFDataTestSupport", package: "WMFData"),
                           .product(name: "WMFDataMocks", package: "WMFData")])
    ],
    // Bumped tools-version to unlock per-target swiftSettings/swiftLanguageMode syntax.
    // Language mode is explicitly pinned to .v5 (warnings-only) until this package
    // completes its strict-concurrency burn-down and flips to .v6.
    swiftLanguageModes: [.v5]
)
