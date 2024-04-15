// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "theme-changer",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/fumoboy007/msgpack-swift.git", from: "2.0.1"),
    ],

    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "theme-changer", dependencies: [
                .product(name: "DMMessagePack", package: "msgpack-swift"),
            ]),
    ]
)
