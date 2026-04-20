import Foundation

/// A rate cache that persists exchange rates to a JSON file on disk.
///
/// Reads the full cache from disk on initialization and writes atomically
/// on every store/clear operation.
public actor LocalFileRateCache: RateCaching {
    private var storage: [String: ConversionRateTable]
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.storage = Self.loadFromDisk(fileURL: fileURL)
    }

    public func conversionTable(for baseCurrencyCode: String) -> ConversionRateTable? {
        storage[baseCurrencyCode]
    }

    public func rate(from source: Currency, to target: Currency) -> Decimal? {
        conversionTable(for: source.code)?.rate(for: target)
    }

    public func store(_ rateTable: ConversionRateTable, for baseCurrencyCode: String) throws {
        if let existing = storage[baseCurrencyCode] {
            var rates = existing.rates
            for (key, value) in rateTable.rates {
                rates[key] = value
            }
            storage[baseCurrencyCode] = ConversionRateTable(base: rateTable.base, rates: rates, date: rateTable.date)
        } else {
            storage[baseCurrencyCode] = rateTable
        }
        try writeToDisk()
    }

    public func availableCurrencyCodes() -> [String] {
        Array(storage.keys)
    }

    public func clear() throws {
        storage.removeAll()
        try writeToDisk()
    }

    // MARK: - Disk I/O

    private func writeToDisk() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(storage)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func loadFromDisk(fileURL: URL) -> [String: ConversionRateTable] {
        guard let data = try? Data(contentsOf: fileURL) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([String: ConversionRateTable].self, from: data)) ?? [:]
    }
}
