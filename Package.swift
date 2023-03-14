// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "smtp-nio",
    products: [.library(name: "SMTPNIO", targets: ["SMTPNIO"])],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.48.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.23.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.15.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.1.0"),
    ],
    targets: [
        .target(name: "SMTPNIO", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOFoundationCompat", package: "swift-nio"),
            .product(name: "NIOSSL", package: "swift-nio-ssl"),
            .product(name: "NIOTLS", package: "swift-nio-ssl"),
            .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
            .product(name: "NIOExtras", package: "swift-nio-extras"),
        ]),
        .testTarget(name: "SMTPNIOTests", dependencies: ["SMTPNIO"]),
    ]
)