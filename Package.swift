// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ios-salary-count",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ios-salary-count",
            targets: ["ios-salary-count"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ios-salary-count",
            dependencies: [],
            path: "Sources/ios-salary-count",
            resources: [
                .process("Info.plist")
            ]),
        .testTarget(
            name: "ios-salary-countTests",
            dependencies: ["ios-salary-count"],
            path: "Tests"),
    ]
) 