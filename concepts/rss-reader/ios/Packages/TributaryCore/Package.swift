// swift-tools-version: 6.2
import PackageDescription

// Pure Swift, no dependencies, no UI. Everything in here must also build on Linux so the
// parser and archive round-trip tests can run in CI without a Mac. When the shared Rust
// core lands (see CONCEPT.md section 9) it replaces the implementations behind these
// same public types.
let package = Package(
    name: "TributaryCore",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "TributaryCore", targets: ["TributaryCore"]),
    ],
    targets: [
        .target(
            name: "TributaryCore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "TributaryCoreTests",
            dependencies: ["TributaryCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
