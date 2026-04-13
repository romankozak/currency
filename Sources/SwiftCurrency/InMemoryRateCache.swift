import Foundation

/// An in-memory rate cache backed by a dictionary.
public actor InMemoryRateCache: RateCache {
    private var storage: [String: ConversionRate] = [:]
    private let ttl: TimeInterval

    public init(ttl: TimeInterval = 3600) {
        self.ttl = ttl
    }

    public func conversionRate(for baseCurrencyCode: String) -> ConversionRate? {
        guard let entry = storage[baseCurrencyCode],
              Date().timeIntervalSince(entry.date) < ttl else {
            return nil
        }
        return entry
    }

    public func rate(from source: Currency, to target: Currency) -> Decimal? {
        conversionRate(for: source.code)?.rate(for: target)
    }

    public func store(_ rate: ConversionRate, for baseCurrencyCode: String) {
        if let existing = storage[baseCurrencyCode] {
            var merged = existing.rates
            for (key, value) in rate.rates {
                merged[key] = value
            }
            storage[baseCurrencyCode] = ConversionRate(
                base: rate.base, rates: merged, date: rate.date
            )
        } else {
            storage[baseCurrencyCode] = rate
        }
    }

    public func allBaseCurrencyCodes() -> [String] {
        Array(storage.keys)
    }

    public func clear() {
        storage.removeAll()
    }
}
