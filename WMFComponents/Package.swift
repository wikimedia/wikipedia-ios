// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WMFComponents",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "WMFComponents",
            targets: ["WMFComponents"])
    ],
    dependencies: [
        .package(name: "WMFData", path: "../WMFData/")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "WMFComponentsObjC",
            dependencies: [],
            path: "Sources/WMFComponentsObjC"),
        .target(
            name: "WMFComponents",
            dependencies: [
                "WMFComponentsObjC",
                .product(name: "WMFData", package: "WMFData"),
                .product(name: "WMFDataMocks", package: "WMFData")
            ],
            path: "Sources/WMFComponents"),
        .testTarget(
            name: "WMFComponentsTests",
            dependencies: ["WMFComponents",
                           .product(name: "WMFDataMocks", package: "WMFData")])
    ]
)
