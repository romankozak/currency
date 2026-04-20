import Foundation

/// A cache for exchange rate data, keyed by base currency code.
///
/// The cache stores and returns data as-is, with no expiration logic.
/// Callers are responsible for deciding whether cached data is fresh enough to use.
public protocol RateCaching: Sendable {
    /// Retrieves the cached `ConversionRateTable` for a base currency code, or `nil` if absent.
    func conversionTable(for baseCurrencyCode: String) async -> ConversionRateTable?

    /// Returns the exchange rate from `source` to `target` using cached data, or `nil` if absent.
    func rate(from source: Currency, to target: Currency) async -> Decimal?

    /// Stores or merges a `ConversionRateTable` into the cache for the given base currency code.
    ///
    /// If an entry already exists for the same code, the rates are merged
    /// (new rates overwrite existing ones for the same target currency).
    func store(_ rateTable: ConversionRateTable, for baseCurrencyCode: String) async

    /// Returns all base currency codes currently held in the cache (expired or not).
    func availableCurrencyCodes() async -> [String]

    /// Removes all cached entries.
    func clear() async
}

public extension RateCaching {
    /// Dictionary-style read access. Equivalent to `conversionTable(for:)`.
    subscript(baseCurrencyCode: String) -> ConversionRateTable? {
        get async { await conversionTable(for: baseCurrencyCode) }
    }
}
