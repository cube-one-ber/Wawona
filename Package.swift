// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Wawona",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "WawonaUI", type: .dynamic, targets: ["WawonaUI"]),
        .library(name: "WawonaModel", type: .dynamic, targets: ["WawonaModel"]),
        .library(name: "WawonaWatch", type: .dynamic, targets: ["WawonaWatch"])
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.6.35"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.10.5"),
        .package(url: "https://source.skip.tools/skip-fuse.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-model.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "WawonaModel",
            dependencies: [
                .product(name: "SkipFuse", package: "skip-fuse"),
                .product(name: "SkipModel", package: "skip-model")
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        .target(
            name: "WawonaUI",
            dependencies: [
                "WawonaModel",
                .product(name: "SkipFuseUI", package: "skip-fuse-ui")
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        .target(
            name: "WawonaWatch",
            dependencies: [
                "WawonaModel",
                .product(name: "SkipFuse", package: "skip-fuse")
            ],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        )
    ]
)
