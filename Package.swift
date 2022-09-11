// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SwiftServer",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "SwiftServer",
            targets: ["SwiftServer"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftServer",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftServerTests",
            dependencies: ["SwiftServer"]
        )
    ]
)
