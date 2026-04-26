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
        ),
        .testTarget(
            name: "BluxClientTests",
            dependencies: ["BluxClient"],
            path: "Tests/BluxClientTests"
        ),
        // Public API surface는 wrapper SDK(RN/Flutter)와 동일한 access modifier로 검증한다.
        // BluxClientTests는 @testable import라 internal까지 보이므로 public→internal 강등 회귀를
        // 잡지 못한다. 이 testTarget은 plain `import BluxClient`만 쓰는 별도 모듈로 격리.
        .testTarget(
            name: "BluxClientPublicAPITests",
            dependencies: ["BluxClient"],
            path: "Tests/BluxClientPublicAPITests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
