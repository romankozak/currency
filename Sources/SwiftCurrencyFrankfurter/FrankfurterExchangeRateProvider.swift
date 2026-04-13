import Foundation
import SwiftCurrency

/// An exchange rate provider that fetches live rates from the free
/// [Frankfurter API](https://www.frankfurter.app), powered by the European Central Bank.
///
/// No API key required. Supports ~30 major currencies.
///
/// ```swift
/// import SwiftCurrency
/// import SwiftCurrencyFrankfurter
///
/// let provider = FrankfurterExchangeRateProvider()
/// let rates = try await provider.fetchRates(for: .usd)
/// let eurRate = rates.rate(for: .eur)
/// ```
public struct FrankfurterExchangeRateProvider: ExchangeRateProvider {
    private let session: URLSession
    private let baseURL: URL

    public init(session: URLSession = .shared, baseURL: URL = URL(string: "https://api.frankfurter.app")!) {
        self.session = session
        self.baseURL = baseURL
    }

    public func fetchRates(for base: Currency) async throws -> ConversionRate {
        var components = URLComponents(url: baseURL.appendingPathComponent("latest"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "from", value: base.code)]
        let url = components.url!

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

        let decoded: FrankfurterResponse
        do {
            decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        } catch {
            throw ExchangeRateError.decodingError(underlying: error)
        }

        var rates = decoded.rates
        rates[base.code] = 1.0

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let date = dateFormatter.date(from: decoded.date) ?? Date()

        return ConversionRate(base: base, rates: rates, date: date)
    }
}

private struct FrankfurterResponse: Decodable {
    let base: String
    let date: String
    let rates: [String: Double]
}
