import Foundation

/// An in-memory rate cache backed by a dictionary.
public actor InMemoryRateCache: RateCaching {
    private struct CacheEntry: Sendable {
        let rateTable: ConversionRateTable
        let storedAt: Date
    }

    private var storage: [String: CacheEntry] = [:]
    private let ttl: TimeInterval

    public init(ttl: TimeInterval = 3600) {
        self.ttl = ttl
    }

    public func conversionTable(for baseCurrencyCode: String) -> ConversionRateTable? {
        guard let entry = storage[baseCurrencyCode],
              Date().timeIntervalSince(entry.storedAt) < ttl else {
            return nil
        }
        return entry.rateTable
    }

    public func rate(from source: Currency, to target: Currency) -> Decimal? {
        conversionTable(for: source.code)?.rate(for: target)
    }

    public func store(_ rateTable: ConversionRateTable, for baseCurrencyCode: String) {
        let merged: ConversionRateTable
        if let existing = storage[baseCurrencyCode] {
            var rates = existing.rateTable.rates
            for (key, value) in rateTable.rates {
                rates[key] = value
            }
            merged = ConversionRateTable(base: rateTable.base, rates: rates, date: rateTable.date)
        } else {
            merged = rateTable
        }
        storage[baseCurrencyCode] = CacheEntry(rateTable: merged, storedAt: Date())
    }

    public func allBaseCurrencyCodes() -> [String] {
        Array(storage.keys)
    }

    public func clear() {
        storage.removeAll()
    }
}
