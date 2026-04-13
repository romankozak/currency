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
