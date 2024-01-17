// swift-tools-version:5.0
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
        .target(name: "Optimizely", 
                path: "Sources",
                exclude: ["Supporting Files/PrivacyInfo.xcprivacy"],
                resources: [.copy("Supporting Files/PrivacyInfo.xcprivacy")]
        )
    ],
    swiftLanguageVersions: [.v5]
)
