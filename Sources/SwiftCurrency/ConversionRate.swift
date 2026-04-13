import Foundation

/// A snapshot of exchange rates from a base currency.
public struct ConversionRate: Sendable, Codable {
    /// The base currency these rates are relative to.
    public let base: Currency

    /// Map of currency code to its rate relative to `base`.
    public let rates: [String: Decimal]

    /// When this rate data was fetched or generated.
    public let date: Date

    public init(base: Currency, rates: [String: Decimal], date: Date = Date()) {
        self.base = base
        self.rates = rates
        self.date = date
    }

    /// Returns the exchange rate from `base` to the given currency, or `nil` if unavailable.
    public func rate(for currency: Currency) -> Decimal? {
        if currency == base { return 1 }
        return rates[currency.code]
    }

    /// Converts an amount from `base` to the given currency, or `nil` if the rate is unavailable.
    public func convert(_ amount: Decimal, to currency: Currency) -> Decimal? {
        guard let r = rate(for: currency) else { return nil }
        return amount * r
    }
}
