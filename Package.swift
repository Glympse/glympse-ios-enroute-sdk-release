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
            targets: ["EnRouteApi", "GlympseKit", "GlympsePrivateAPI"])
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
            url: "https://github.com/Glympse/glympse-ios-enroute-sdk-release/releases/download/2.111.310/EnRouteApi.zip",
            checksum: "641a4d2ffd8b22310e505c7626c35d84dfbdddb4d59d503e103d8363156f3ab6"
        ),
        .binaryTarget(
            name: "GlympseKit",
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.111.310/GlympseKit.zip",
            checksum: "f750afcb362c4884a1c3a863056034ad3a31a998de1647735bce439bd1cf4024"
        ),
        .binaryTarget(
            name: "GlympsePrivateAPI",
            url: "https://github.com/Glympse/glympse-ios-sdk-release/releases/download/2.111.310/GlympsePrivateAPI.zip",
            checksum: "514092eed9f9f1ff5621aac5c076f4e5b3f33c4a431fdedd27c16e0f15218895"
        ),
    ]
)
