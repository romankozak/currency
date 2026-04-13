import Foundation

/// A snapshot of exchange rates from a base currency.
public struct ConversionRate: Sendable {
    /// The base currency these rates are relative to.
    public let base: Currency

    /// Map of currency code to its rate relative to `base`.
    public let rates: [String: Double]

    /// When this rate data was fetched or generated.
    public let date: Date

    public init(base: Currency, rates: [String: Double], date: Date = Date()) {
        self.base = base
        self.rates = rates
        self.date = date
    }

    /// Returns the exchange rate from `base` to the given currency, or `nil` if unavailable.
    public func rate(for currency: Currency) -> Double? {
        if currency == base { return 1.0 }
        return rates[currency.code]
    }

    /// Converts an amount from `base` to the given currency, or `nil` if the rate is unavailable.
    public func convert(_ amount: Double, to currency: Currency) -> Double? {
        guard let r = rate(for: currency) else { return nil }
        return amount * r
    }
}
