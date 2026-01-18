// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkdownOpener",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MarkdownOpener", targets: ["MarkdownOpener"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0")
    ],
    targets: [
        .executableTarget(
            name: "MarkdownOpener",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
