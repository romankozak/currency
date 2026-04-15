/// A currency identified by its ISO 4217 code, symbol, and descriptive name.
public struct Currency: Sendable, Hashable, Codable {
    /// The ISO 4217 currency code (e.g. "USD", "EUR").
    public let code: String

    /// The display symbol (e.g. "$", "€", "¥").
    public let symbol: String

    /// The human-readable name (e.g. "US Dollar").
    public let name: String

    /// The number of minor units (decimal places). Most currencies use 2.
    public let minorUnits: Int

    public init(code: String, symbol: String, name: String, minorUnits: Int = 2) {
        self.code = code
        self.symbol = symbol
        self.name = name
        self.minorUnits = minorUnits
    }
}

extension Currency: CustomStringConvertible {
    public var description: String {
        "\(code) (\(symbol))"
    }
}

// MARK: - Lookup

extension Currency {
    private static let currencyByCode: [String: Currency] = {
        Dictionary(uniqueKeysWithValues: allCurrencies.map { ($0.code, $0) })
    }()

    /// Returns the currency matching the given ISO 4217 code, or `nil` if unknown.
    public static func find(_ code: String) -> Currency? {
        currencyByCode[code.uppercased()]
    }
}
