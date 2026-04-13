import ProjectDescription

let project = Project(
    name: "SwiftCurrency",
    targets: [
        // Core library
        .target(
            name: "SwiftCurrency",
            destinations: [.iPhone, .iPad, .mac, .appleWatch, .appleTv],
            product: .framework,
            bundleId: "com.swiftcurrency.core",
            deploymentTargets: .multiplatform(iOS: "15.0", macOS: "12.0", watchOS: "8.0", tvOS: "15.0"),
            sources: ["Sources/SwiftCurrency/**"],
            dependencies: []
        ),

        // Frankfurter provider (separate module)
        .target(
            name: "SwiftCurrencyFrankfurter",
            destinations: [.iPhone, .iPad, .mac, .appleWatch, .appleTv],
            product: .framework,
            bundleId: "com.swiftcurrency.frankfurter",
            deploymentTargets: .multiplatform(iOS: "15.0", macOS: "12.0", watchOS: "8.0", tvOS: "15.0"),
            sources: ["Sources/SwiftCurrencyFrankfurter/**"],
            dependencies: [
                .target(name: "SwiftCurrency"),
            ]
        ),

        // Core tests
        .target(
            name: "SwiftCurrencyTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.swiftcurrency.core.tests",
            deploymentTargets: .multiplatform(iOS: "15.0", macOS: "12.0"),
            sources: ["Tests/SwiftCurrencyTests/**"],
            dependencies: [
                .target(name: "SwiftCurrency"),
            ]
        ),

        // Frankfurter tests
        .target(
            name: "SwiftCurrencyFrankfurterTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.swiftcurrency.frankfurter.tests",
            deploymentTargets: .multiplatform(iOS: "15.0", macOS: "12.0"),
            sources: ["Tests/SwiftCurrencyFrankfurterTests/**"],
            dependencies: [
                .target(name: "SwiftCurrencyFrankfurter"),
                .target(name: "SwiftCurrency"),
            ]
        ),
    ]
)
