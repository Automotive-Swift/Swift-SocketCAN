// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swift-SocketCAN",
    products: [
        .library(
            name: "Swift-SocketCAN",
            targets: ["Swift-SocketCAN"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AutomotiveSwift/Swift-CAN", branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CSocketCAN",
            dependencies: []
        ),
        .target(
            name: "Swift-SocketCAN",
            dependencies: [
                "CSocketCAN",
                "Swift-CAN"
            ]),
        .testTarget(
            name: "Swift-SocketCANTests",
            dependencies: ["Swift-SocketCAN"]),
    ]
)
