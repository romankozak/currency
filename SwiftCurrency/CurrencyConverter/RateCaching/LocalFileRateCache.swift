import Foundation

/// A rate cache that persists exchange rates to a JSON file on disk.
///
/// Reads the full cache from disk on initialization and writes atomically
/// on every store/clear operation.
public actor LocalFileRateCache: RateCaching {
    private struct CacheEntry: Sendable, Codable {
        let rateTable: ConversionRateTable
        let storedAt: Date
    }

    private var storage: [String: CacheEntry]
    private let ttl: TimeInterval
    private let fileURL: URL

    public init(fileURL: URL, ttl: TimeInterval = 3600) {
        self.fileURL = fileURL
        self.ttl = ttl
        self.storage = Self.loadFromDisk(fileURL: fileURL)
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
        writeToDisk()
    }

    public func availableCurrencyCodes() -> [String] {
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

    private static func loadFromDisk(fileURL: URL) -> [String: CacheEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([String: CacheEntry].self, from: data)) ?? [:]
    }
}
