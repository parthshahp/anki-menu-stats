// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "anki-menu-stats",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "anki-menu-stats",
            targets: ["AnkiMenuStatsApp"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "AnkiMenuStatsApp",
            path: "Sources/AnkiMenuStatsApp"
        ),
    ]
)
