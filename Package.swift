// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Transcript",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "1.1.0"),
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.15.6")
    ],
    targets: [
        .executableTarget(
            name: "Transcript",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
                .product(name: "FluidAudio", package: "FluidAudio")
            ],
            exclude: ["README.md", "AGENTS.md"]
        ),
        .testTarget(
            name: "TranscriptTests",
            dependencies: ["Transcript"]
        )
    ]
)
