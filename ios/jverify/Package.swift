// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "jverify",
    platforms: [
        // jverification-sdk's Swift package requires iOS 15.0.
        .iOS("15.0")
    ],
    products: [
        .library(name: "jverify", targets: ["jverify"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/jpush/jcore-sdk.git", from: "5.4.0"),
        // The upstream 3.4.7 tag was rewritten. Pin its current revision so
        // SwiftPM does not reject the package on machines that cached the old tag.
        .package(
            url: "https://github.com/jpush/jverification-sdk.git",
            revision: "7ac501dd898d69a2d004d93a28d0d11f91e7ad3e"
        )
    ],
    targets: [
        .target(
            name: "jverify",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "JCore", package: "jcore-sdk"),
                .product(name: "JVerification", package: "jverification-sdk")
            ],
            cSettings: [
                .headerSearchPath("include/jverify")
            ],
            linkerSettings: [
                // JverifyPlugin directly accesses ASIdentifierManager when
                // the Dart caller enables IDFA collection.
                .linkedFramework("AdSupport")
            ]
        )
    ]
)
