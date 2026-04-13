import Foundation
import Testing
@testable import SwiftCurrency

// MARK: - Currency

@Test func currencyProperties() {
    let usd = Currency.usd
    #expect(usd.code == "USD")
    #expect(usd.symbol == "$")
    #expect(usd.name == "US Dollar")
    #expect(usd.minorUnits == 2)
}

@Test func currencyDefaultMinorUnits() {
    let custom = Currency(code: "TST", symbol: "T", name: "Test")
    #expect(custom.minorUnits == 2)
}

@Test func currencyCustomMinorUnits() {
    let custom = Currency(code: "TST", symbol: "T", name: "Test", minorUnits: 5)
    #expect(custom.minorUnits == 5)
}

@Test func currencyEquality() {
    #expect(Currency.eur == Currency.eur)
    #expect(Currency.usd != Currency.gbp)

    let copy = Currency(code: "USD", symbol: "$", name: "US Dollar")
    #expect(copy == Currency.usd)
}

@Test func currencyInequalityDifferentFields() {
    let a = Currency(code: "USD", symbol: "$", name: "US Dollar")
    let b = Currency(code: "USD", symbol: "US$", name: "US Dollar")
    #expect(a != b)
}

@Test func currencyDescription() {
    #expect(Currency.jpy.description == "JPY (¥)")
    #expect(Currency.eur.description == "EUR (€)")
    #expect(Currency.gbp.description == "GBP (£)")
}

@Test func currencyHashable() {
    let set: Set<Currency> = [.usd, .eur, .usd]
    #expect(set.count == 2)
    #expect(set.contains(.usd))
    #expect(set.contains(.eur))
}

@Test func currencyCodable() throws {
    let original = Currency.jpy
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(Currency.self, from: data)
    #expect(decoded == original)
    #expect(decoded.minorUnits == 0)
}

// MARK: - Currency.find

@Test func findCurrencyUppercase() {
    #expect(Currency.find("USD") == .usd)
    #expect(Currency.find("EUR") == .eur)
}

@Test func findCurrencyLowercase() {
    #expect(Currency.find("eur") == .eur)
    #expect(Currency.find("gbp") == .gbp)
}

@Test func findCurrencyMixedCase() {
    #expect(Currency.find("Jpy") == .jpy)
}

@Test func findCurrencyInvalid() {
    #expect(Currency.find("INVALID") == nil)
    #expect(Currency.find("") == nil)
    #expect(Currency.find("US") == nil)
}

// MARK: - Currency static members

@Test func minorUnitsVariation() {
    #expect(Currency.jpy.minorUnits == 0)
    #expect(Currency.krw.minorUnits == 0)
    #expect(Currency.bhd.minorUnits == 3)
    #expect(Currency.kwd.minorUnits == 3)
    #expect(Currency.omr.minorUnits == 3)
    #expect(Currency.usd.minorUnits == 2)
    #expect(Currency.eur.minorUnits == 2)
}

@Test func allCurrenciesNotEmpty() {
    #expect(Currency.allCurrencies.count > 100)
}

@Test func allCurrenciesContainsCommonCurrencies() {
    let codes = Set(Currency.allCurrencies.map(\.code))
    for expected in ["USD", "EUR", "GBP", "JPY", "CHF", "CAD", "AUD", "CNY", "INR", "BRL"] {
        #expect(codes.contains(expected), "Missing \(expected)")
    }
}

@Test func allCurrenciesHasUniqueCodesExceptALL() {
    let codes = Currency.allCurrencies.map(\.code)
    let unique = Set(codes)
    #expect(codes.count == unique.count)
}

@Test func allLekHasCorrectCode() {
    #expect(Currency.allLek.code == "ALL")
    #expect(Currency.allLek.name == "Albanian Lek")
    #expect(Currency.find("ALL") == .allLek)
}

@Test func tryKeywordCurrency() {
    #expect(Currency.try.code == "TRY")
    #expect(Currency.try.symbol == "₺")
}

// MARK: - ConversionRate

@Test func conversionRateSelf() {
    let rate = ConversionRate(base: .usd, rates: ["EUR": 0.92, "GBP": 0.79])
    #expect(rate.rate(for: .usd) == 1.0)
}

@Test func conversionRateForCurrency() {
    let rate = ConversionRate(base: .usd, rates: ["EUR": 0.92, "GBP": 0.79])
    #expect(rate.rate(for: .eur) == 0.92)
    #expect(rate.rate(for: .gbp) == 0.79)
}

@Test func conversionRateConvert() {
    let rate = ConversionRate(base: .usd, rates: ["EUR": 0.92])
    let result = rate.convert(100, to: .eur)
    #expect(result != nil)
    #expect(abs(result! - 92.0) < 0.001)
}

@Test func conversionRateConvertZero() {
    let rate = ConversionRate(base: .usd, rates: ["EUR": 0.92])
    #expect(rate.convert(0, to: .eur) == 0.0)
}

@Test func conversionRateConvertLargeAmount() {
    let rate = ConversionRate(base: .usd, rates: ["JPY": 149.50])
    let result = rate.convert(1_000_000, to: .jpy)!
    #expect(abs(result - 149_500_000.0) < 0.001)
}

@Test func conversionRateMissing() {
    let rate = ConversionRate(base: .usd, rates: [:])
    #expect(rate.rate(for: .eur) == nil)
    #expect(rate.convert(100, to: .eur) == nil)
}

@Test func conversionRateStoresDate() {
    let fixedDate = Date(timeIntervalSince1970: 1_000_000)
    let rate = ConversionRate(base: .usd, rates: [:], date: fixedDate)
    #expect(rate.date == fixedDate)
}

// MARK: - LocalExchangeRateProvider

@Test func localProviderUSD() async throws {
    let provider = LocalExchangeRateProvider()
    let rates = try await provider.fetchRates(for: .usd)
    #expect(rates.base == .usd)
    #expect(rates.rate(for: .usd) == 1.0)
    #expect(rates.rate(for: .eur) != nil)
}

@Test func localProviderEUR() async throws {
    let provider = LocalExchangeRateProvider()
    let rates = try await provider.fetchRates(for: .eur)
    #expect(rates.base == .eur)
    #expect(abs(rates.rate(for: .eur)! - 1.0) < 0.001)
    let eurToUsd = rates.rate(for: .usd)!
    #expect(eurToUsd > 1.0 && eurToUsd < 1.2)
}

@Test func localProviderJPY() async throws {
    let provider = LocalExchangeRateProvider()
    let rates = try await provider.fetchRates(for: .jpy)
    #expect(rates.base == .jpy)
    #expect(abs(rates.rate(for: .jpy)! - 1.0) < 0.001)
    let jpyToUsd = rates.rate(for: .usd)!
    #expect(jpyToUsd > 0.005 && jpyToUsd < 0.01)
}

@Test func localProviderCrossRateConsistency() async throws {
    let provider = LocalExchangeRateProvider()
    let usdRates = try await provider.fetchRates(for: .usd)
    let eurRates = try await provider.fetchRates(for: .eur)

    let usdToEur = usdRates.rate(for: .eur)!
    let eurToUsd = eurRates.rate(for: .usd)!
    #expect(abs(usdToEur * eurToUsd - 1.0) < 0.001)
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
    let exotic = Currency(code: "XXX", symbol: "?", name: "Unknown")
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

// MARK: - Mock provider for CurrencyConverter tests

private struct MockProvider: ExchangeRateProvider {
    var rates: [String: Double]

    func fetchRates(for base: Currency) async throws -> ConversionRate {
        ConversionRate(base: base, rates: rates)
    }
}

private struct FailingProvider: ExchangeRateProvider {
    func fetchRates(for base: Currency) async throws -> ConversionRate {
        throw ExchangeRateError.invalidResponse
    }
}

// MARK: - CurrencyConverter

@Test func converterLocalRates() async throws {
    let converter = CurrencyConverter()
    let rate = try await converter.rate(from: .usd, to: .eur)
    #expect(rate > 0.8 && rate < 1.0)
}

@Test func converterConvert() async throws {
    let converter = CurrencyConverter()
    let amount = try await converter.convert(100, from: .usd, to: .gbp)
    #expect(amount > 70 && amount < 90)
}

@Test func converterSameCurrency() async throws {
    let converter = CurrencyConverter()
    let rate = try await converter.rate(from: .usd, to: .usd)
    #expect(rate == 1.0)
    let amount = try await converter.convert(42.5, from: .eur, to: .eur)
    #expect(abs(amount - 42.5) < 0.001)
}

@Test func converterConvertZero() async throws {
    let converter = CurrencyConverter()
    let amount = try await converter.convert(0, from: .usd, to: .jpy)
    #expect(amount == 0.0)
}

@Test func converterWithCustomProvider() async throws {
    let mock = MockProvider(rates: ["EUR": 2.0, "GBP": 3.0])
    let converter = CurrencyConverter(provider: mock)
    let rate = try await converter.rate(from: .usd, to: .eur)
    #expect(rate == 2.0)
    let amount = try await converter.convert(10, from: .usd, to: .gbp)
    #expect(amount == 30.0)
}

@Test func converterThrowsForUnsupportedTarget() async {
    let mock = MockProvider(rates: ["EUR": 0.92])
    let converter = CurrencyConverter(provider: mock)
    do {
        _ = try await converter.rate(from: .usd, to: .jpy)
        #expect(Bool(false), "Should have thrown")
    } catch let error as ExchangeRateError {
        switch error {
        case .unsupportedCurrency(let code):
            #expect(code == "JPY")
        default:
            #expect(Bool(false), "Wrong error case: \(error)")
        }
    } catch {
        #expect(Bool(false), "Wrong error type")
    }
}

@Test func converterPropagatesProviderError() async {
    let converter = CurrencyConverter(provider: FailingProvider())
    do {
        _ = try await converter.rate(from: .usd, to: .eur)
        #expect(Bool(false), "Should have thrown")
    } catch let error as ExchangeRateError {
        switch error {
        case .invalidResponse:
            break // expected
        default:
            #expect(Bool(false), "Wrong error case: \(error)")
        }
    } catch {
        #expect(Bool(false), "Wrong error type")
    }
}

@Test func converterCaching() async throws {
    let mock = MockProvider(rates: ["EUR": 0.92])
    let converter = CurrencyConverter(provider: mock, cacheDuration: 3600)
    let rate1 = try await converter.rate(from: .usd, to: .eur)
    let rate2 = try await converter.rate(from: .usd, to: .eur)
    #expect(rate1 == rate2)
}

@Test func converterClearCache() async throws {
    let mock = MockProvider(rates: ["EUR": 0.92])
    let converter = CurrencyConverter(provider: mock, cacheDuration: 3600)
    _ = try await converter.rate(from: .usd, to: .eur)
    await converter.clearCache()
    let rate = try await converter.rate(from: .usd, to: .eur)
    #expect(rate == 0.92)
}

@Test func converterExpiredCacheRefetches() async throws {
    let mock = MockProvider(rates: ["EUR": 0.92])
    let converter = CurrencyConverter(provider: mock, cacheDuration: 0)
    let rate1 = try await converter.rate(from: .usd, to: .eur)
    let rate2 = try await converter.rate(from: .usd, to: .eur)
    #expect(rate1 == rate2)
    #expect(rate1 == 0.92)
}

// MARK: - ExchangeRateError

@Test func errorDescriptions() {
    let unsupported = ExchangeRateError.unsupportedCurrency("XYZ")
    #expect(unsupported.errorDescription?.contains("XYZ") == true)

    let invalid = ExchangeRateError.invalidResponse
    #expect(invalid.errorDescription != nil)

    let network = ExchangeRateError.networkError(underlying: URLError(.notConnectedToInternet))
    #expect(network.errorDescription?.contains("Network") == true)

    struct FakeError: Error, LocalizedError {
        var errorDescription: String? { "fake" }
    }
    let decoding = ExchangeRateError.decodingError(underlying: FakeError())
    #expect(decoding.errorDescription?.contains("decode") == true)
}

// MARK: - Local provider round-trip conversions

@Test func localProviderRoundTrip() async throws {
    let provider = LocalExchangeRateProvider()
    let usdRates = try await provider.fetchRates(for: .usd)

    let euros = usdRates.convert(100, to: .eur)!

    let eurRates = try await provider.fetchRates(for: .eur)
    let backToUsd = eurRates.convert(euros, to: .usd)!

    #expect(abs(backToUsd - 100.0) < 0.01)
}

// MARK: - fetchRate(from:to:) single-pair

@Test func localProviderFetchRatePair() async throws {
    let provider = LocalExchangeRateProvider()
    let result = try await provider.fetchRate(from: .usd, to: .eur)
    #expect(result.base == .usd)
    #expect(result.rate(for: .eur) != nil)
    // Should only contain the target currency (plus base implicit)
    #expect(result.rates.count == 1)
}

@Test func localProviderFetchRateSameCurrency() async throws {
    let provider = LocalExchangeRateProvider()
    let result = try await provider.fetchRate(from: .usd, to: .usd)
    #expect(result.rate(for: .usd) == 1.0)
}

@Test func localProviderFetchRateConsistentWithFull() async throws {
    let provider = LocalExchangeRateProvider()
    let full = try await provider.fetchRates(for: .usd)
    let pair = try await provider.fetchRate(from: .usd, to: .gbp)
    #expect(full.rate(for: .gbp) == pair.rate(for: .gbp))
}

@Test func localProviderFetchRateUnsupportedBase() async {
    let provider = LocalExchangeRateProvider()
    let exotic = Currency(code: "XXX", symbol: "?", name: "Unknown")
    do {
        _ = try await provider.fetchRate(from: exotic, to: .usd)
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

@Test func localProviderFetchRateUnsupportedTarget() async {
    let provider = LocalExchangeRateProvider()
    let exotic = Currency(code: "XXX", symbol: "?", name: "Unknown")
    do {
        _ = try await provider.fetchRate(from: .usd, to: exotic)
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

@Test func converterUsesSinglePairMethod() async throws {
    let mock = MockProvider(rates: ["EUR": 2.0, "GBP": 3.0])
    let converter = CurrencyConverter(provider: mock)
    let rate = try await converter.rate(from: .usd, to: .eur)
    #expect(rate == 2.0)
}
