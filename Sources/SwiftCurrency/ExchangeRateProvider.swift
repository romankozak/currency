/// A provider that can fetch exchange rates for a given base currency.
public protocol ExchangeRateProvider: Sendable {
    /// Fetches exchange rates relative to the given base currency.
    func fetchRates(for base: Currency) async throws -> ConversionRate
}
