// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "LocalHoldoutsBugBash",
    platforms: [.macOS(.v10_14)],
    dependencies: [
        .package(path: "../.."),  // points to swift-sdk root
    ],
    targets: [
        .target(
            name: "LocalHoldoutsBugBash",
            dependencies: [
                .product(name: "Optimizely", package: "swift-sdk-bugbash"),
            ],
            path: "Sources"
        ),
    ]
)
