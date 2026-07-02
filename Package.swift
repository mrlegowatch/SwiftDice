// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftDice",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftDice",
            targets: ["SwiftDice"]),
    ],
    targets: [
        .target(
            name: "SwiftDice",
            path: "Sources/SwiftDice"),
        .testTarget(
            name: "SwiftDiceTests",
            dependencies: ["SwiftDice"],
            path: "Tests/SwiftDiceTests"),
    ]
)
