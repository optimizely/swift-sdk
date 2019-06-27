// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Optimizely",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9)
    ],
    products: [
        .library(name: "Optimizely",
                 targets: ["Optimizely"])
    ],
    targets: [
        .target(name: "Optimizely", path: "Sources")
    ],
    swiftLanguageVersions: [.v5]
)
