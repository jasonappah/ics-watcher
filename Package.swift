// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ics-watcher",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "ics-watcher", targets: ["ics-watcher"])
    ],
    targets: [
        .executableTarget(
            name: "ics-watcher",
            dependencies: [],
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        )
    ]
)
