// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EnRouteAPI",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "EnRouteApi",
            targets: ["EnRouteApi", "GlympseKit", "GlympsePrivateAPI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(
            name: "EnRouteApi",
            url: "https://github.com/Glympse/glympse-ios-enroute-sdk-release/releases/download/2.110.306/EnRouteApi.zip",
            checksum: "edf6654a641a5afdb39f546367f3f52aa910cf99fa180835a886a1d79453bfb4"
        ),
        .binaryTarget(
            name: "GlympseKit",
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.110.306/GlympseKit.zip",
            checksum: "a77c712283ab4e77c87ce9f41afb86fb830a6b24624e84c792627870bfd41d54"
        ),
        .binaryTarget(
            name: "GlympsePrivateAPI",
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.110.306/GlympsePrivateAPI.zip",
            checksum: "48bd31b6592dca063732ded772d68dc5fb1c47a258d62a67ab256d887eb1bfcb"
        ),
    ]
)
