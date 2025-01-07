// swift-tools-version:5.3
// The Swift tools version declares the version of the PackageDescription library,
// the minimum version of the Swift tools and Swift language compatibility version to process the manifest,
// and the minimum version of the Swift tools that are needed to use the Swift package.

import PackageDescription

let package = Package(
    name: "Optimizely",
    platforms: [
        .iOS(.v10),
        .tvOS(.v10),
        .macOS(.v10_14),
        .watchOS(.v3)
    ],
    products: [
        .library(name: "Optimizely",
                 targets: ["Optimizely"])
    ],
    targets: [
        .target(
            name: "Optimizely",
            path: "Sources",
            resources: [.process("Supporting Files/PrivacyInfo.xcprivacy")]
        )
    ]
)
