import Foundation
import Testing
@testable import SwiftCurrency

// MARK: - Mock providers

private struct MockProvider: ExchangeRateProvider {
    var rates: [String: Decimal]
    var failingBases: Set<String> = []

    func fetchRates(for base: Currency) async throws -> ConversionRateTable {
        if failingBases.contains(base.code) {
            throw ExchangeRateError.invalidResponse
        }
        return ConversionRateTable(base: base, rates: rates)
    }
}

private struct FailingProvider: ExchangeRateProvider {
    func fetchRates(for base: Currency) async throws -> ConversionRateTable {
        throw ExchangeRateError.invalidResponse
    }
}

/// A provider whose fetchRate always returns an empty ConversionRateTable (no rates for target).
private struct EmptyPairProvider: ExchangeRateProvider {
    func fetchRates(for base: Currency) async throws -> ConversionRateTable {
        ConversionRateTable(base: base, rates: [:])
    }

    func fetchRate(from base: Currency, to target: Currency) async throws -> ConversionRateTable {
        ConversionRateTable(base: base, rates: [:])
    }
}

// MARK: - CurrencyConverter

@Test func converterLocalRates() async throws {
    let converter = CurrencyConverter()
    let rate = try await converter.rate(from: .usd, to: .eur)
    #expect(rate > Decimal(string: "0.8")! && rate < 1)
}

@Test func converterConvert() async throws {
    let converter = CurrencyConverter()
    let amount = try await converter.convert(100, from: .usd, to: .gbp)
    #expect(amount > 70 && amount < 90)
}

@Test func converterSameCurrency() async throws {
    let converter = CurrencyConverter()
    let rate = try await converter.rate(from: .usd, to: .usd)
    #expect(rate == 1)
    let amount: Decimal = try await converter.convert(Decimal(string: "42.5")!, from: .eur, to: .eur)
    #expect(abs(amount - Decimal(string: "42.5")!) < Decimal(string: "0.001")!)
}

@Test func converterConvertZero() async throws {
    let converter = CurrencyConverter()
    let amount = try await converter.convert(0, from: .usd, to: .jpy)
    #expect(amount == 0)
}

@Test func converterWithCustomProvider() async throws {
    let mock = MockProvider(rates: ["EUR": 2, "GBP": 3])
    let converter = CurrencyConverter(provider: mock)
    let rate = try await converter.rate(from: .usd, to: .eur)
    #expect(rate == 2)
    let amount = try await converter.convert(10, from: .usd, to: .gbp)
    #expect(amount == 30)
}

@Test func converterThrowsForUnsupportedTarget() async {
    let mock = MockProvider(rates: ["EUR": Decimal(string: "0.92")!])
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
    let mock = MockProvider(rates: ["EUR": Decimal(string: "0.92")!])
    let converter = CurrencyConverter(provider: mock, cacheDuration: 3600)
    let rate1 = try await converter.rate(from: .usd, to: .eur)
    let rate2 = try await converter.rate(from: .usd, to: .eur)
    #expect(rate1 == rate2)
}

@Test func converterClearCache() async throws {
    let mock = MockProvider(rates: ["EUR": Decimal(string: "0.92")!])
    let converter = CurrencyConverter(provider: mock, cacheDuration: 3600)
    _ = try await converter.rate(from: .usd, to: .eur)
    await converter.clearCache()
    let rate = try await converter.rate(from: .usd, to: .eur)
    #expect(rate == Decimal(string: "0.92")!)
}

@Test func converterExpiredCacheRefetches() async throws {
    let mock = MockProvider(rates: ["EUR": Decimal(string: "0.92")!])
    let converter = CurrencyConverter(provider: mock, cacheDuration: 0)
    let rate1 = try await converter.rate(from: .usd, to: .eur)
    let rate2 = try await converter.rate(from: .usd, to: .eur)
    #expect(rate1 == rate2)
    #expect(rate1 == Decimal(string: "0.92")!)
}

@Test func converterUsesSinglePairMethod() async throws {
    let mock = MockProvider(rates: ["EUR": 2, "GBP": 3])
    let converter = CurrencyConverter(provider: mock)
    let rate = try await converter.rate(from: .usd, to: .eur)
    #expect(rate == 2)
}

@Test func converterCachePopulatedAfterRate() async throws {
    let mock = MockProvider(rates: ["EUR": Decimal(string: "0.92")!, "GBP": Decimal(string: "0.79")!])
    let converter = CurrencyConverter(provider: mock, cacheDuration: 3600)
    // First call populates cache
    _ = try await converter.rate(from: .usd, to: .eur)
    // Second call for a different target should use merged cache
    let gbpRate = try await converter.rate(from: .usd, to: .gbp)
    #expect(gbpRate == Decimal(string: "0.79")!)
}

@Test func converterThrowsWhenFetchRateReturnsMissingTarget() async {
    let converter = CurrencyConverter(provider: EmptyPairProvider())
    do {
        _ = try await converter.rate(from: .usd, to: .eur)
        #expect(Bool(false), "Should have thrown")
    } catch let error as ExchangeRateError {
        switch error {
        case .unsupportedCurrency(let code):
            #expect(code == "EUR")
        default:
            #expect(Bool(false), "Wrong error case: \(error)")
        }
    } catch {
        #expect(Bool(false), "Wrong error type: \(error)")
    }
}

// MARK: - refreshCache

@Test func refreshCacheWithAdditionalCurrencies() async throws {
    let mock = MockProvider(rates: ["EUR": Decimal(string: "0.92")!, "GBP": Decimal(string: "0.79")!])
    let converter = CurrencyConverter(provider: mock, cacheDuration: 3600)
    try await converter.refreshCache(refreshCached: false, additionalCurrencies: [.usd, .eur])
    // Now cached — should return from cache
    let rate = try await converter.rate(from: .usd, to: .eur)
    #expect(rate == Decimal(string: "0.92")!)
}

@Test func refreshCacheRefreshesCachedKeys() async throws {
    let mock = MockProvider(rates: ["EUR": Decimal(string: "0.92")!])
    let converter = CurrencyConverter(provider: mock, cacheDuration: 3600)
    // Populate cache for USD
    _ = try await converter.rate(from: .usd, to: .eur)
    // Refresh should refetch USD
    try await converter.refreshCache()
}

@Test func refreshCacheNoopWhenEmpty() async throws {
    let converter = CurrencyConverter(provider: FailingProvider(), cacheDuration: 3600)
    // No cache, no additional currencies — should not throw
    try await converter.refreshCache(refreshCached: true, additionalCurrencies: [])
}

@Test func refreshCachePartialFailure() async {
    let mock = MockProvider(rates: ["EUR": Decimal(string: "0.92")!], failingBases: ["EUR"])
    let converter = CurrencyConverter(provider: mock, cacheDuration: 3600)
    do {
        try await converter.refreshCache(refreshCached: false, additionalCurrencies: [.usd, .eur])
        #expect(Bool(false), "Should have thrown")
    } catch let error as ExchangeRateError {
        switch error {
        case .refreshFailed(let currencies):
            #expect(currencies.count == 1)
            #expect(currencies.first?.code == "EUR")
        default:
            #expect(Bool(false), "Wrong error case: \(error)")
        }
    } catch {
        #expect(Bool(false), "Wrong error type: \(error)")
    }
}

@Test func refreshCacheStillCachesSuccessfulOnPartialFailure() async throws {
    let mock = MockProvider(rates: ["EUR": Decimal(string: "0.92")!], failingBases: ["EUR"])
    let converter = CurrencyConverter(provider: mock, cacheDuration: 3600)
    do {
        try await converter.refreshCache(refreshCached: false, additionalCurrencies: [.usd, .eur])
    } catch {
        // expected partial failure
    }
    // USD should have been cached successfully
    let rate = try await converter.rate(from: .usd, to: .eur)
    #expect(rate == Decimal(string: "0.92")!)
}

// MARK: - CurrencyConverter with injected cache

@Test func converterWithDiskCache() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let diskCache = DiskRateCache(fileURL: url, ttl: 3600)
    let converter = CurrencyConverter(cache: diskCache)
    let rate = try await converter.rate(from: .usd, to: .eur)
    #expect(rate > Decimal(string: "0.8")! && rate < 1)

    // Verify it was persisted
    let cache2 = DiskRateCache(fileURL: url, ttl: 3600)
    #expect(await cache2.rate(from: .usd, to: .eur) != nil)
}
