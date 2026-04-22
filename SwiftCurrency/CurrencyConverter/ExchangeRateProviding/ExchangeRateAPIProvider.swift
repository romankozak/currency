import Foundation

/// An exchange rate provider that fetches live rates from the free
/// [ExchangeRate-API](https://www.exchangerate-api.com) open endpoint,
/// a US-based service (Charleston, SC).
///
/// No API key required. Supports 160+ currencies, updated daily.
///
/// ```swift
/// import SwiftCurrency
///
/// let provider = ExchangeRateAPIProvider()
/// let rates = try await provider.fetchRates(for: .usd)
/// let eurRate = rates.rate(for: .eur)
/// ```
public struct ExchangeRateAPIProvider: ExchangeRateProviding {
    private let session: URLSession
    private let baseURL: URL

    public init(session: URLSession = .shared, baseURL: URL = URL(string: "https://open.er-api.com/v6/latest")!) {
        self.session = session
        self.baseURL = baseURL
    }

    public func fetchRates(for base: Currency) async throws -> ConversionRateTable {
        let url = baseURL.appendingPathComponent(base.code)
        let decoded = try await fetch(url: url)

        guard decoded.result == "success" else {
            throw ExchangeRateError.invalidResponse
        }

        return ConversionRateTable(base: base, rates: decoded.rates, date: Date(timeIntervalSince1970: decoded.timeLastUpdateUnix))
    }

    private func fetch(url: URL) async throws -> ExchangeRateAPIResponse {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw ExchangeRateError.networkError(underlying: error)
        }

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ExchangeRateError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(ExchangeRateAPIResponse.self, from: data)
        } catch {
            throw ExchangeRateError.decodingError(underlying: error)
        }
    }
}

private struct ExchangeRateAPIResponse: Decodable {
    let result: String
    let baseCode: String
    let timeLastUpdateUnix: TimeInterval
    let rates: [String: Decimal]

    enum CodingKeys: String, CodingKey {
        case result
        case baseCode = "base_code"
        case timeLastUpdateUnix = "time_last_update_unix"
        case rates
    }
}
