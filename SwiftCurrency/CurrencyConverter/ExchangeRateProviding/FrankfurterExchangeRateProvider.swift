import Foundation

/// An exchange rate provider that fetches live rates from the free
/// [Frankfurter API](https://www.frankfurter.app), powered by the European Central Bank.
///
/// No API key required. Supports ~30 major currencies.
///
/// ```swift
/// import SwiftCurrency
///
/// let provider = FrankfurterExchangeRateProvider()
/// let rates = try await provider.fetchRates(for: .usd)
/// let eurRate = rates.rate(for: .eur)
/// ```
public struct FrankfurterExchangeRateProvider: ExchangeRateProviding {
    private let session: URLSession
    private let baseURL: URL

    public init(session: URLSession = .shared, baseURL: URL = URL(string: "https://api.frankfurter.app")!) {
        self.session = session
        self.baseURL = baseURL
    }

    public func fetchRate(from base: Currency, to target: Currency) async throws -> ConversionRateTable {
        if base == target {
            return ConversionRateTable(base: base, rates: [target.code: 1])
        }

        var components = URLComponents(url: baseURL.appendingPathComponent("latest"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "from", value: base.code),
            URLQueryItem(name: "to", value: target.code),
        ]

        let decoded = try await fetch(url: components.url!)

        var rates = decoded.rates
        rates[base.code] = 1

        return ConversionRateTable(base: base, rates: rates, date: parseDate(decoded.date))
    }

    public func fetchRates(for base: Currency) async throws -> ConversionRateTable {
        var components = URLComponents(url: baseURL.appendingPathComponent("latest"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "from", value: base.code)]

        let decoded = try await fetch(url: components.url!)

        var rates = decoded.rates
        rates[base.code] = 1

        return ConversionRateTable(base: base, rates: rates, date: parseDate(decoded.date))
    }

    private func fetch(url: URL) async throws -> FrankfurterResponse {
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
            return try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        } catch {
            throw ExchangeRateError.decodingError(underlying: error)
        }
    }

    private func parseDate(_ string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter.date(from: string) ?? Date()
    }
}

private struct FrankfurterResponse: Decodable {
    let base: String
    let date: String
    let rates: [String: Decimal]
}
