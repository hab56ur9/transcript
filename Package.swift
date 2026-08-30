// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "VoiceScribe",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "1.1.0"),
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.15.6")
    ],
    targets: [
        .executableTarget(
            name: "VoiceScribe",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
                .product(name: "FluidAudio", package: "FluidAudio")
            ]
        ),
        .testTarget(
            name: "VoiceScribeTests",
            dependencies: ["VoiceScribe"]
        )
    ]
)
