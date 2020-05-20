// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Optimizely",
    platforms: [
        .iOS(.v10),
        .tvOS(.v10)
    ],
    products: [
        .library(name: "Optimizely",
                 targets: ["Optimizely"])
    ],
    targets: [
        .target(name: "Optimizely",
            //    swiftSettings: [.define("OPT_DBG", .when(configuration: .release))],
                path: "Sources"
        )
    
    ],
    swiftLanguageVersions: [.v5]
)
