import Foundation
import Testing
@testable import SwiftCurrency

// MARK: - FrankfurterExchangeRateProvider unit tests (no network)

@Test func frankfurterProviderConformsToProtocol() {
    let provider: any ExchangeRateProvider = FrankfurterExchangeRateProvider()
    #expect(type(of: provider) is FrankfurterExchangeRateProvider.Type)
}

@Test func frankfurterProviderCustomBaseURL() {
    let customURL = URL(string: "https://custom.api.example.com")!
    let provider = FrankfurterExchangeRateProvider(baseURL: customURL)
    // Just verify it can be constructed with a custom URL
    #expect(type(of: provider) == FrankfurterExchangeRateProvider.self)
}

@Test func frankfurterProviderCustomSession() {
    let config = URLSessionConfiguration.ephemeral
    let session = URLSession(configuration: config)
    let provider = FrankfurterExchangeRateProvider(session: session)
    #expect(type(of: provider) == FrankfurterExchangeRateProvider.self)
}

@Test func frankfurterProviderUsableWithConverter() async throws {
    // Verify it can be plugged into CurrencyConverter without compile errors
    let provider = FrankfurterExchangeRateProvider(
        baseURL: URL(string: "https://invalid.test")!
    )
    let converter = CurrencyConverter(provider: provider)
    // Don't actually call — just verify type compatibility
    #expect(type(of: converter) == CurrencyConverter.self)
}

// MARK: - Live API contract tests

@Test func frankfurterAPIResponseParsesCorrectly() async throws {
    let provider = FrankfurterExchangeRateProvider()
    let rateTable = try await provider.fetchRate(from: .usd, to: .eur)

    // Base currency must match what we requested
    #expect(rateTable.base == .usd)

    // Must contain the target rate and it must be a sane positive value
    let eurRate = rateTable.rate(for: .eur)
    #expect(eurRate != nil, "EUR rate missing — API response structure may have changed")
    #expect(eurRate! > 0, "EUR rate must be positive")

    // Date must have been parsed (not the fallback Date())
    let calendar = Calendar(identifier: .gregorian)
    let year = calendar.component(.year, from: rateTable.date)
    #expect(year >= 2024, "Date appears unparsed or invalid — API date format may have changed")
}

@Test func frankfurterAPIFullRateTableParsesCorrectly() async throws {
    let provider = FrankfurterExchangeRateProvider()
    let rateTable = try await provider.fetchRates(for: .usd)

    #expect(rateTable.base == .usd)
    #expect(rateTable.rate(for: .usd) == 1, "Base currency self-rate must be 1")

    // Frankfurter returns ~30 currencies; verify a handful of majors are present
    let expectedCurrencies: [Currency] = [.eur, .gbp, .jpy]
    for currency in expectedCurrencies {
        let rate = rateTable.rate(for: currency)
        #expect(rate != nil, "\(currency.code) missing — API may have dropped this currency")
        #expect(rate! > 0, "\(currency.code) rate must be positive")
    }

    // Should have a reasonable number of rates (ECB publishes ~30)
    #expect(rateTable.rates.count >= 20, "Too few rates (\(rateTable.rates.count)) — API structure may have changed")
}
