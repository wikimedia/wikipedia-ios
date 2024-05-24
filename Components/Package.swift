// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Components",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Components",
            targets: ["Components"])
    ],
    dependencies: [
        .package(name: "WKData", path: "../WKData/")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ComponentsObjC",
            dependencies: [],
            path: "Sources/ComponentsObjC"),
        .target(
            name: "Components",
            dependencies: [
                "ComponentsObjC",
                .product(name: "WKData", package: "WKData"),
                .product(name: "WKDataMocks", package: "WKData")
            ],
            path: "Sources/Components"),
        .testTarget(
            name: "ComponentsTests",
            dependencies: ["Components",
                           .product(name: "WKDataMocks", package: "WKData")])
    ]
)
