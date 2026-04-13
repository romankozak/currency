import Foundation

/// A cache for exchange rate data, keyed by base currency code.
///
/// Implementations handle TTL expiration internally — protocol methods
/// return `nil` for expired entries.
public protocol RateCaching: Sendable {
    /// Retrieves the cached `ConversionRateTable` for a base currency code,
    /// or `nil` if missing or expired.
    func conversionRate(for baseCurrencyCode: String) async -> ConversionRateTable?

    /// Returns the exchange rate from `source` to `target` using cached data,
    /// or `nil` if missing or expired.
    func rate(from source: Currency, to target: Currency) async -> Decimal?

    /// Stores or merges a `ConversionRateTable` into the cache for the given base currency code.
    ///
    /// If an entry already exists for the same code, the rates are merged
    /// (new rates overwrite existing ones for the same target currency).
    func store(_ rateTable: ConversionRateTable, for baseCurrencyCode: String) async

    /// Returns all base currency codes currently held in the cache (expired or not).
    func allBaseCurrencyCodes() async -> [String]

    /// Removes all cached entries.
    func clear() async
}
