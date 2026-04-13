/// A provider that can fetch exchange rates for a given base currency.
public protocol ExchangeRateProviding: Sendable {
    /// Fetches exchange rates relative to the given base currency.
    func fetchRates(for base: Currency) async throws -> ConversionRateTable

    /// Fetches the exchange rate from one currency to another.
    ///
    /// Providers should override this to call a dedicated API endpoint
    /// that returns only the requested pair, avoiding fetching the full rate table.
    ///
    /// The default implementation falls back to ``fetchRates(for:)`` and extracts the target rate.
    func fetchRate(from base: Currency, to target: Currency) async throws -> ConversionRateTable
}

extension ExchangeRateProviding {
    public func fetchRate(from base: Currency, to target: Currency) async throws -> ConversionRateTable {
        let full = try await fetchRates(for: base)
        guard let rate = full.rate(for: target) else {
            throw ExchangeRateError.unsupportedCurrency(target.code)
        }
        return ConversionRateTable(base: base, rates: [target.code: rate], date: full.date)
    }
}
