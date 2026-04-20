import Foundation

/// Errors that can occur when fetching exchange rates.
public enum ExchangeRateError: Error, LocalizedError, Equatable {
    case unsupportedCurrency(String)
    case networkError(underlying: Error)
    case invalidResponse
    case decodingError(underlying: Error)
    case refreshFailed(currencies: [Currency])

    public static func == (lhs: ExchangeRateError, rhs: ExchangeRateError) -> Bool {
        switch (lhs, rhs) {
        case (.unsupportedCurrency(let a), .unsupportedCurrency(let b)): return a == b
        case (.networkError, .networkError): return true
        case (.invalidResponse, .invalidResponse): return true
        case (.decodingError, .decodingError): return true
        case (.refreshFailed(let a), .refreshFailed(let b)): return a == b
        default: return false
        }
    }

    public var errorDescription: String? {
        switch self {
        case .unsupportedCurrency(let code):
            "Unsupported currency: \(code)"
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            "Invalid response from exchange rate API"
        case .decodingError(let error):
            "Failed to decode response: \(error.localizedDescription)"
        case .refreshFailed(let currencies):
            "Failed to refresh rates for: \(currencies.map(\.code).joined(separator: ", "))"
        }
    }
}
