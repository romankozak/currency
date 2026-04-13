// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SwiftCurrency",
    products: [
        .library(name: "SwiftCurrency", targets: ["SwiftCurrency"]),
        .library(name: "SwiftCurrencyFrankfurter", targets: ["SwiftCurrencyFrankfurter"]),
    ],
    targets: [
        .target(name: "SwiftCurrency"),
        .target(name: "SwiftCurrencyFrankfurter", dependencies: ["SwiftCurrency"]),
    ]
)
