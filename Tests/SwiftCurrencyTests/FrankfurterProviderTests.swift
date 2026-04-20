import Foundation
import Testing
@testable import SwiftCurrency

// MARK: - FrankfurterExchangeRateProvider unit tests (no network)

@Test func frankfurterProviderConformsToProtocol() {
    let provider: any ExchangeRateProviding = FrankfurterExchangeRateProvider()
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
