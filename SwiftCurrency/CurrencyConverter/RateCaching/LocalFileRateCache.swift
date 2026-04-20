import Foundation

/// A rate cache that persists exchange rates to a JSON file on disk.
///
/// Storage is loaded lazily on first access. Call ``loadFromDisk()`` explicitly
/// to surface I/O or decode errors before reading or writing.
public actor LocalFileRateCache: RateCaching {
    private var storage: [String: ConversionRateTable]?
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    // MARK: - Explicit load

    /// Loads the cache from disk, replacing any in-memory state.
    /// Throws if the file exists but cannot be read or decoded.
    /// A missing file is treated as an empty cache.
    public func loadFromDisk() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            storage = [:]
            return
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        storage = try decoder.decode([String: ConversionRateTable].self, from: data)
    }

    // MARK: - RateCaching

    public func conversionTable(for baseCurrencyCode: String) -> ConversionRateTable? {
        if storage == nil { try? loadFromDisk() }
        return storage?[baseCurrencyCode]
    }

    public func rate(from source: Currency, to target: Currency) -> Decimal? {
        conversionTable(for: source.code)?.rate(for: target)
    }

    public func store(_ rateTable: ConversionRateTable) throws {
        let baseCurrencyCode = rateTable.base.code
        if storage == nil { try loadFromDisk() }
        if let existing = storage?[baseCurrencyCode] {
            var rates = existing.rates
            for (key, value) in rateTable.rates {
                rates[key] = value
            }
            storage![baseCurrencyCode] = ConversionRateTable(base: rateTable.base, rates: rates, date: rateTable.date)
        } else {
            storage![baseCurrencyCode] = rateTable
        }
        try writeToDisk()
    }

    public func availableCurrencyCodes() -> [String] {
        if storage == nil { try? loadFromDisk() }
        return Array((storage ?? [:]).keys)
    }

    public func clear() throws {
        storage = [:]
        try writeToDisk()
    }

    // MARK: - Disk I/O

    private func writeToDisk() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(storage ?? [:])
        try data.write(to: fileURL, options: .atomic)
    }
}
