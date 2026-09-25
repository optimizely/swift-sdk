// swift-tools-version:6.4
// The Swift tools version declares the version of the PackageDescription library,
// the minimum version of the Swift tools and Swift language compatibility version to process the manifest,
// and the minimum version of the Swift tools that are needed to use the Swift package.

import PackageDescription

let package = Package(
    name: "Optimizely",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "Optimizely",
                 targets: ["Optimizely"])
    ],
    targets: [
        .target(
            name: "Optimizely",
            path: "Sources",
            exclude: ["Supporting Files/Info.plist"],
            resources: [.copy("Supporting Files/PrivacyInfo.xcprivacy")]
        )
    ],
    swiftLanguageVersions: [.v5]
)
