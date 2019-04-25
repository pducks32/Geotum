// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Geotum",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Geotum",
            targets: ["Geotum"]),
        .executable(
            name: "geotum", targets: ["GeotumCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", .branch("swift-5.0-branch"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Geotum",
            dependencies: []),
        .target(
            name: "GeotumCLI",
            dependencies: ["Geotum", "SPMUtility"],
            path: "Sources/CLI"),
        .testTarget(
            name: "GeotumTests",
            dependencies: ["Geotum"]),
    ]
)
