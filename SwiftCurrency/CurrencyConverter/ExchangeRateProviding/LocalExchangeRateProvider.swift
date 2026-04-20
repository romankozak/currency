import Foundation

/// An exchange rate provider backed by hardcoded stub data.
/// Useful for testing, previews, and offline use.
///
/// Rates are approximate and relative to USD.
public struct LocalExchangeRateProvider: ExchangeRateProviding {
    /// Approximate rates relative to 1 USD (as of early 2025).
    public static let stubbedRatesFromUSD: [String: Decimal] = [
        "USD": 1,
        "EUR": Decimal(string: "0.92")!,
        "GBP": Decimal(string: "0.79")!,
        "JPY": Decimal(string: "149.50")!,
        "CHF": Decimal(string: "0.88")!,
        "CAD": Decimal(string: "1.36")!,
        "AUD": Decimal(string: "1.53")!,
        "NZD": Decimal(string: "1.67")!,
        "CNY": Decimal(string: "7.24")!,
        "INR": Decimal(string: "83.12")!,
        "BRL": Decimal(string: "4.97")!,
        "MXN": Decimal(string: "17.15")!,
        "ZAR": Decimal(string: "18.63")!,
        "KRW": 1320,
        "SGD": Decimal(string: "1.34")!,
        "HKD": Decimal(string: "7.82")!,
        "NOK": Decimal(string: "10.52")!,
        "SEK": Decimal(string: "10.42")!,
        "DKK": Decimal(string: "6.88")!,
        "PLN": Decimal(string: "4.02")!,
        "THB": Decimal(string: "35.10")!,
        "IDR": 15650,
        "MYR": Decimal(string: "4.72")!,
        "PHP": Decimal(string: "56.20")!,
        "CZK": Decimal(string: "22.80")!,
        "HUF": 358,
        "ILS": Decimal(string: "3.67")!,
        "CLP": 890,
        "PEN": Decimal(string: "3.72")!,
        "COP": 3950,
        "ARS": 830,
        "EGP": Decimal(string: "30.90")!,
        "NGN": 790,
        "PKR": 280,
        "BDT": 110,
        "VND": 24300,
        "TRY": Decimal(string: "30.20")!,
        "UAH": Decimal(string: "37.50")!,
        "RON": Decimal(string: "4.59")!,
        "BGN": Decimal(string: "1.80")!,
        "HRK": Decimal(string: "6.93")!,
        "ISK": 137,
        "RUB": 91,
        "TWD": Decimal(string: "31.50")!,
        "SAR": Decimal(string: "3.75")!,
        "AED": Decimal(string: "3.67")!,
        "QAR": Decimal(string: "3.64")!,
        "KWD": Decimal(string: "0.31")!,
        "BHD": Decimal(string: "0.38")!,
        "OMR": Decimal(string: "0.39")!,
        "JOD": Decimal(string: "0.71")!,
        "KES": 153,
        "GHS": Decimal(string: "12.30")!,
        "TZS": 2510,
        "UGX": 3780,
        "RWF": 1250,
        "ETB": Decimal(string: "56.50")!,
        "MAD": Decimal(string: "10.05")!,
        "TND": Decimal(string: "3.12")!,
        "LYD": Decimal(string: "4.85")!,
        "DZD": Decimal(string: "134.50")!,
        "GEL": Decimal(string: "2.70")!,
        "AMD": 405,
        "AZN": Decimal(string: "1.70")!,
        "KZT": 455,
        "UZS": 12300,
        "KGS": 89,
        "TJS": Decimal(string: "10.95")!,
        "TMT": Decimal(string: "3.50")!,
        "MMK": 2100,
        "KHR": 4100,
        "LAK": 20600,
        "MNT": 3430,
        "LKR": 325,
        "NPR": 133,
        "AFN": 73,
        "IQD": 1310,
        "IRR": 42000,
        "SYP": 13000,
        "LBP": 15000,
        "YER": 250,
    ]

    public init() {}

    public func fetchRates(for base: Currency) async throws -> ConversionRateTable {
        let usdRates = Self.stubbedRatesFromUSD

        guard let baseToUSD = usdRates[base.code] else {
            throw ExchangeRateError.unsupportedCurrency(base.code)
        }

        // Convert all rates to be relative to the requested base currency.
        var converted: [String: Decimal] = [:]
        for (code, usdRate) in usdRates {
            converted[code] = usdRate / baseToUSD
        }

        return ConversionRateTable(base: base, rates: converted)
    }
}
