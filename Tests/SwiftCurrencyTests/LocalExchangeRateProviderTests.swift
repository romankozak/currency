import Foundation
import Testing
@testable import SwiftCurrency

// MARK: - LocalExchangeRateProvider

@Test func localProviderUSD() async throws {
    let provider = LocalExchangeRateProvider()
    let rates = try await provider.fetchRates(for: .usd)
    #expect(rates.base == .usd)
    #expect(rates.rate(for: .usd) == 1)
    #expect(rates.rate(for: .eur) != nil)
}

@Test func localProviderEUR() async throws {
    let provider = LocalExchangeRateProvider()
    let rates = try await provider.fetchRates(for: .eur)
    #expect(rates.base == .eur)
    let eurRate = rates.rate(for: .eur)!
    #expect(abs(eurRate - 1) < Decimal(string: "0.001")!)
    let eurToUsd = rates.rate(for: .usd)!
    #expect(eurToUsd > 1 && eurToUsd < Decimal(string: "1.2")!)
}

@Test func localProviderJPY() async throws {
    let provider = LocalExchangeRateProvider()
    let rates = try await provider.fetchRates(for: .jpy)
    #expect(rates.base == .jpy)
    let jpyRate = rates.rate(for: .jpy)!
    #expect(abs(jpyRate - 1) < Decimal(string: "0.001")!)
    let jpyToUsd = rates.rate(for: .usd)!
    #expect(jpyToUsd > Decimal(string: "0.005")! && jpyToUsd < Decimal(string: "0.01")!)
}

@Test func localProviderCrossRateConsistency() async throws {
    let provider = LocalExchangeRateProvider()
    let usdRates = try await provider.fetchRates(for: .usd)
    let eurRates = try await provider.fetchRates(for: .eur)

    let usdToEur = usdRates.rate(for: .eur)!
    let eurToUsd = eurRates.rate(for: .usd)!
    #expect(abs(usdToEur * eurToUsd - 1) < Decimal(string: "0.001")!)
}

@Test func localProviderAllStubbedCurrenciesReturned() async throws {
    let provider = LocalExchangeRateProvider()
    let rates = try await provider.fetchRates(for: .usd)
    for code in LocalExchangeRateProvider.stubbedRatesFromUSD.keys {
        #expect(rates.rates[code] != nil, "Missing rate for \(code)")
    }
}

@Test func localProviderUnsupportedCurrency() async {
    let provider = LocalExchangeRateProvider()
    let exotic = Currency(code: "XXX", symbol: "?")
    do {
        _ = try await provider.fetchRates(for: exotic)
        #expect(Bool(false), "Should have thrown")
    } catch let error as ExchangeRateError {
        switch error {
        case .unsupportedCurrency(let code):
            #expect(code == "XXX")
        default:
            #expect(Bool(false), "Wrong error case: \(error)")
        }
    } catch {
        #expect(Bool(false), "Wrong error type: \(error)")
    }
}

// MARK: - Local provider round-trip conversions

@Test func localProviderRoundTrip() async throws {
    let provider = LocalExchangeRateProvider()
    let usdRates = try await provider.fetchRates(for: .usd)

    let euros = usdRates.convert(100, to: .eur)!

    let eurRates = try await provider.fetchRates(for: .eur)
    let backToUsd = eurRates.convert(euros, to: .usd)!

    #expect(abs(backToUsd - 100) < Decimal(string: "0.01")!)
}
