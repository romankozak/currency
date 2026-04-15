// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftCurrency",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "SwiftCurrency", targets: ["SwiftCurrency"]),
    ],
    targets: [
        .target(name: "SwiftCurrency", path: "SwiftCurrency"),
        .testTarget(
            name: "SwiftCurrencyTests",
            dependencies: ["SwiftCurrency"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
