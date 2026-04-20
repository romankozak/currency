import Foundation

/// An in-memory rate cache backed by a dictionary.
public actor InMemoryRateCache: RateCaching {
    private var storage: [String: ConversionRateTable] = [:]

    public init() {}

    public func conversionTable(for baseCurrencyCode: String) -> ConversionRateTable? {
        storage[baseCurrencyCode]
    }

    public func rate(from source: Currency, to target: Currency) -> Decimal? {
        conversionTable(for: source.code)?.rate(for: target)
    }

    public func store(_ rateTable: ConversionRateTable, for baseCurrencyCode: String) {
        if let existing = storage[baseCurrencyCode] {
            var rates = existing.rates
            for (key, value) in rateTable.rates {
                rates[key] = value
            }
            storage[baseCurrencyCode] = ConversionRateTable(base: rateTable.base, rates: rates, date: rateTable.date)
        } else {
            storage[baseCurrencyCode] = rateTable
        }
    }

    public func availableCurrencyCodes() -> [String] {
        Array(storage.keys)
    }

    public func clear() {
        storage.removeAll()
    }
}
