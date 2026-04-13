import Foundation

/// An in-memory rate cache backed by a dictionary.
public actor InMemoryRateCache: RateCaching {
    private var storage: [String: ConversionRateTable] = [:]
    private let ttl: TimeInterval

    public init(ttl: TimeInterval = 3600) {
        self.ttl = ttl
    }

    public func conversionRate(for baseCurrencyCode: String) -> ConversionRateTable? {
        guard let entry = storage[baseCurrencyCode],
              Date().timeIntervalSince(entry.date) < ttl else {
            return nil
        }
        return entry
    }

    public func rate(from source: Currency, to target: Currency) -> Decimal? {
        conversionRate(for: source.code)?.rate(for: target)
    }

    public func store(_ rateTable: ConversionRateTable, for baseCurrencyCode: String) {
        if let existing = storage[baseCurrencyCode] {
            var merged = existing.rates
            for (key, value) in rateTable.rates {
                merged[key] = value
            }
            storage[baseCurrencyCode] = ConversionRateTable(
                base: rateTable.base, rates: merged, date: rateTable.date
            )
        } else {
            storage[baseCurrencyCode] = rateTable
        }
    }

    public func allBaseCurrencyCodes() -> [String] {
        Array(storage.keys)
    }

    public func clear() {
        storage.removeAll()
    }
}
