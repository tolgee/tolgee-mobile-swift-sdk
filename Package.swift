// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tolgee",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Tolgee",
            targets: ["Tolgee"]),
        .plugin(
            name: "TolgeeKeysPlugin",
            targets: ["TolgeeKeysPlugin"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Tolgee"
        ),
        .target(
            name: "TolgeeKeysGeneratorCore"
        ),
        .executableTarget(
            name: "TolgeeKeysGenerator",
            dependencies: ["TolgeeKeysGeneratorCore"]
        ),
        .plugin(
            name: "TolgeeKeysPlugin",
            capability: .buildTool(),
            dependencies: ["TolgeeKeysGenerator"]
        ),
        .testTarget(
            name: "TolgeeKeysGeneratorTests",
            dependencies: ["TolgeeKeysGeneratorCore"]
        ),
        .testTarget(
            name: "TolgeeTests",
            dependencies: ["Tolgee"],
            resources: [
                .process("Resources")
            ],
            plugins: ["TolgeeKeysPlugin"]
        ),
    ]
)
