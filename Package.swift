// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "BluxClient",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "BluxClient",
            targets: ["BluxClient"]
        )
    ],
    targets: [
        .target(
            name: "BluxClient",
            path: "BluxClient/Classes",
            exclude: [".gitkeep"]
        )
    ],
    swiftLanguageVersions: [.v5]
)

