import Foundation

/// A rate cache that persists exchange rates to a JSON file on disk.
///
/// Reads the full cache from disk on initialization and writes atomically
/// on every store/clear operation.
public actor DiskRateCache: RateCache {
    private var storage: [String: ConversionRate]
    private let ttl: TimeInterval
    private let fileURL: URL

    public init(fileURL: URL, ttl: TimeInterval = 3600) {
        self.fileURL = fileURL
        self.ttl = ttl
        self.storage = Self.loadFromDisk(fileURL: fileURL)
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
        writeToDisk()
    }

    public func allBaseCurrencyCodes() -> [String] {
        Array(storage.keys)
    }

    public func clear() {
        storage.removeAll()
        writeToDisk()
    }

    // MARK: - Disk I/O

    private func writeToDisk() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(storage) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func loadFromDisk(fileURL: URL) -> [String: ConversionRate] {
        guard let data = try? Data(contentsOf: fileURL) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([String: ConversionRate].self, from: data)) ?? [:]
    }
}
