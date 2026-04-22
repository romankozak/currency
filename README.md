# SwiftCurrency

A small Swift package for working with ISO 4217 currencies and converting amounts with cached exchange rates.

## Features

- `Currency` type with ISO code, symbol, localized name, and minor units.
- Static currency shortcuts such as `.usd`, `.eur`, and `.gbp`.
- Async `CurrencyConverter` for rates and amount conversion.
- Built-in in-memory and local JSON file rate caches.
- Live rates by default via Frankfurter, with local stub and ExchangeRate-API providers available.

## Requirements

- Swift 5.9+
- iOS 15+, macOS 12+, tvOS 15+, watchOS 8+

## Installation

Add this package in Xcode:

```text
File > Add Package Dependencies...
```

Or add it to `Package.swift`:

```swift
.package(url: "https://github.com/<owner>/<repo>.git", from: "0.1.0")
```

Then add `SwiftCurrency` as a dependency for your target.

## Usage

```swift
import SwiftCurrency

let converter = CurrencyConverter()

let rate = try await converter.rate(from: .usd, to: .eur)
let amount = try await converter.convert(100, from: .usd, to: .gbp)
```

Use local stub rates for tests, previews, or offline work:

```swift
let provider = LocalExchangeRateProvider()
let converter = CurrencyConverter(provider: provider)
let eur = try await converter.convert(100, from: .usd, to: .eur)
```

Use a persistent cache:

```swift
let cacheURL = URL(filePath: "/tmp/swift-currency-rates.json")
let cache = LocalFileRateCache(fileURL: cacheURL)
let converter = CurrencyConverter(cache: cache)
```

## Testing

```sh
swift test
```
