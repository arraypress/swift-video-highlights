// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "VideoHighlights",
    // macOS 26 / iOS 26 so a tool linking this still runs there: only the
    // analysis itself needs macOS 27 (Apple's MediaIntelligence), and it is
    // gated with @available (and weak-linked) rather than raising the floor.
    platforms: [
        .macOS(.v26), .iOS(.v26),
    ],
    products: [
        .library(name: "VideoHighlights", targets: ["VideoHighlights"]),
    ],
    dependencies: [
        // The 720p proxy (hardware export) and the thumbnail frame.
        .package(url: "https://github.com/arraypress/swift-video-forge.git", from: "0.3.1"),
    ],
    targets: [
        .target(
            name: "VideoHighlights",
            dependencies: [
                .product(name: "VideoForge", package: "swift-video-forge"),
            ]
            // MediaIntelligence is autolinked by its import. Every use is
            // `@available(macOS 27, iOS 27, *)`, so the linker weak-links it
            // and the library loads on 26; a build on an SDK without it
            // (`#if canImport`) compiles the API with analysis unavailable.
        ),
        .testTarget(name: "VideoHighlightsTests", dependencies: ["VideoHighlights"]),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
