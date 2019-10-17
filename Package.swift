// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "./Multiplayer-Blackjack",
    products: [
        .library(name: "./Multiplayer-Blackjack", targets: ["App"])
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        /// Any other dependencies ...
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0"),

        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentSQLite", "Leaf", "Vapor"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
