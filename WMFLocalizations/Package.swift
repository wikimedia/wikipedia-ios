// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WMFLocalizations",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WMFLocalizations",
            targets: ["WMFNativeLocalizations", "WMFTranslateWikiLocalizations"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WMFNativeLocalizations",
            path: "Sources/WMFNativeLocalizations",
            resources: [.process("Resources")]),
        .target(
            name: "WMFTranslateWikiLocalizations",
            path: "Sources/WMFTranslateWikiLocalizations",
            resources: [.process("Resources")]),
        .testTarget(
            name: "WMFLocalizationsTests",
            dependencies: ["WMFNativeLocalizations", "WMFTranslateWikiLocalizations"],
            path: "Tests"
        )
    ]
)

/*
 // swift-tools-version: 6.1
 // The swift-tools-version declares the minimum version of Swift required to build this package.

 import PackageDescription

 let package = Package(
     name: "WMFNativeLocalizations",
     defaultLocalization: "en",
     platforms: [.iOS(.v16)],
     products: [
         // Products define the executables and libraries a package produces, making them visible to other packages.
         .library(
             name: "WMFNativeLocalizations",
             targets: ["WMFNativeLocalizations"])
     ],
     targets: [
         // Targets are the basic building blocks of a package, defining a module or a test suite.
         // Targets can depend on other targets in this package and products from dependencies.
         .target(
             name: "WMFNativeLocalizations",
             resources: [.process("Resources")]),
         .testTarget(
             name: "WMFNativeLocalizationsTests",
             dependencies: ["WMFNativeLocalizations"]
         )
     ]
 )

 */
