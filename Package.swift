// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swift-SocketCAN",
    platforms: [
        .macOS("9999"),
        .iOS("9999"),
        .tvOS("9999"),
        .watchOS("9999"),
    ],
    products: [
        .library(name: "Swift-SocketCAN", targets: ["Swift-SocketCAN"]),
        .library(name: "Swift-SocketCAN-ISOTP", targets: ["Swift-SocketCAN-ISOTP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AutomotiveSwift/Swift-CAN", branch: "master")
    ],
    targets: [
        .target(
            name: "CSocketCAN",
            dependencies: []
        ),
        .target(
            name: "Swift-SocketCAN",
            dependencies: [
                "CSocketCAN",
                "Swift-CAN"
            ]
        ),
        .target(
            name: "Swift-SocketCAN-ISOTP",
            dependencies: [
                "CSocketCAN",
                "Swift-CAN",
            ]
        ),
        .testTarget(
            name: "Swift-SocketCANTests",
            dependencies: ["Swift-SocketCAN"]
        ),
        .testTarget(
            name: "Swift-SocketCAN-ISOTPTests",
            dependencies: ["Swift-SocketCAN-ISOTP"]
        )
    ]
)
