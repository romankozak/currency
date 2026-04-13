import Foundation

/// An exchange rate provider backed by hardcoded stub data.
/// Useful for testing, previews, and offline use.
///
/// Rates are approximate and relative to USD.
public struct LocalExchangeRateProvider: ExchangeRateProvider {
    /// Approximate rates relative to 1 USD (as of early 2025).
    public static let stubbedRatesFromUSD: [String: Double] = [
        "USD": 1.0,
        "EUR": 0.92,
        "GBP": 0.79,
        "JPY": 149.50,
        "CHF": 0.88,
        "CAD": 1.36,
        "AUD": 1.53,
        "NZD": 1.67,
        "CNY": 7.24,
        "INR": 83.12,
        "BRL": 4.97,
        "MXN": 17.15,
        "ZAR": 18.63,
        "KRW": 1320.0,
        "SGD": 1.34,
        "HKD": 7.82,
        "NOK": 10.52,
        "SEK": 10.42,
        "DKK": 6.88,
        "PLN": 4.02,
        "THB": 35.10,
        "IDR": 15650.0,
        "MYR": 4.72,
        "PHP": 56.20,
        "CZK": 22.80,
        "HUF": 358.0,
        "ILS": 3.67,
        "CLP": 890.0,
        "PEN": 3.72,
        "COP": 3950.0,
        "ARS": 830.0,
        "EGP": 30.90,
        "NGN": 790.0,
        "PKR": 280.0,
        "BDT": 110.0,
        "VND": 24300.0,
        "TRY": 30.20,
        "UAH": 37.50,
        "RON": 4.59,
        "BGN": 1.80,
        "HRK": 6.93,
        "ISK": 137.0,
        "RUB": 91.0,
        "TWD": 31.50,
        "SAR": 3.75,
        "AED": 3.67,
        "QAR": 3.64,
        "KWD": 0.31,
        "BHD": 0.38,
        "OMR": 0.39,
        "JOD": 0.71,
        "KES": 153.0,
        "GHS": 12.30,
        "TZS": 2510.0,
        "UGX": 3780.0,
        "RWF": 1250.0,
        "ETB": 56.50,
        "MAD": 10.05,
        "TND": 3.12,
        "LYD": 4.85,
        "DZD": 134.50,
        "GEL": 2.70,
        "AMD": 405.0,
        "AZN": 1.70,
        "KZT": 455.0,
        "UZS": 12300.0,
        "KGS": 89.0,
        "TJS": 10.95,
        "TMT": 3.50,
        "MMK": 2100.0,
        "KHR": 4100.0,
        "LAK": 20600.0,
        "MNT": 3430.0,
        "LKR": 325.0,
        "NPR": 133.0,
        "AFN": 73.0,
        "IQD": 1310.0,
        "IRR": 42000.0,
        "SYP": 13000.0,
        "LBP": 15000.0,
        "YER": 250.0,
    ]

    public init() {}

    public func fetchRates(for base: Currency) async throws -> ConversionRate {
        let usdRates = Self.stubbedRatesFromUSD

        guard let baseToUSD = usdRates[base.code] else {
            throw ExchangeRateError.unsupportedCurrency(base.code)
        }

        // Convert all rates to be relative to the requested base currency.
        var converted: [String: Double] = [:]
        for (code, usdRate) in usdRates {
            converted[code] = usdRate / baseToUSD
        }

        return ConversionRate(base: base, rates: converted)
    }
}
