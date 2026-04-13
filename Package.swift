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
        .library(name: "SwiftCurrencyFrankfurter", targets: ["SwiftCurrencyFrankfurter"]),
    ],
    targets: [
        .target(name: "SwiftCurrency"),
        .target(
            name: "SwiftCurrencyFrankfurter",
            dependencies: ["SwiftCurrency"]
        ),
        .testTarget(
            name: "SwiftCurrencyTests",
            dependencies: ["SwiftCurrency"]
        ),
        .testTarget(
            name: "SwiftCurrencyFrankfurterTests",
            dependencies: ["SwiftCurrencyFrankfurter", "SwiftCurrency"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
