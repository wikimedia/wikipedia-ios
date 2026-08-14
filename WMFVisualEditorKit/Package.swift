// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WMFVisualEditorKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "WMFVisualEditorKit",
            targets: ["WMFVisualEditorKit"])
    ],
    targets: [
        .target(
            name: "WMFVisualEditorKit",
            path: "Sources/WMFVisualEditorKit"),
        .testTarget(
            name: "WMFVisualEditorKitTests",
            dependencies: ["WMFVisualEditorKit"],
            resources: [.copy("Fixtures")])
    ],
    // Greenfield package: starts (and stays) in the Swift 6 language mode with
    // strict concurrency, unlike the older packages still burning down to it.
    swiftLanguageModes: [.v6]
)
