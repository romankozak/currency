import Foundation
import Testing
@testable import SwiftCurrency

// MARK: - InMemoryRateCache

@Test func inMemoryStoreAndRetrieve() async {
    let cache = InMemoryRateCache(ttl: 3600)
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rateTable, for: "USD")
    let retrieved = await cache.conversionTable(for: "USD")
    #expect(retrieved != nil)
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
}

@Test func inMemoryRateFromTo() async {
    let cache = InMemoryRateCache(ttl: 3600)
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rateTable, for: "USD")
    #expect(await cache.rate(from: .usd, to: .eur) == Decimal(string: "0.92")!)
    #expect(await cache.rate(from: .usd, to: .gbp) == nil)
}

@Test func inMemoryReturnsNilForMissing() async {
    let cache = InMemoryRateCache(ttl: 3600)
    #expect(await cache.conversionTable(for: "USD") == nil)
    #expect(await cache.rate(from: .usd, to: .eur) == nil)
}

@Test func inMemoryTTLExpiration() async {
    let cache = InMemoryRateCache(ttl: 0)
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rateTable, for: "USD")
    // TTL is 0, so it's already expired
    #expect(await cache.conversionTable(for: "USD") == nil)
    #expect(await cache.rate(from: .usd, to: .eur) == nil)
}

@Test func inMemoryMergesOnStore() async {
    let cache = InMemoryRateCache(ttl: 3600)
    let first = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(first, for: "USD")
    let second = ConversionRateTable(base: .usd, rates: ["GBP": Decimal(string: "0.79")!])
    await cache.store(second, for: "USD")
    let retrieved = await cache.conversionTable(for: "USD")
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
    #expect(retrieved!.rate(for: .gbp) == Decimal(string: "0.79")!)
}

@Test func inMemoryMergeOverwritesExistingKeys() async {
    let cache = InMemoryRateCache(ttl: 3600)
    let first = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(first, for: "USD")
    let second = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.95")!])
    await cache.store(second, for: "USD")
    #expect(await cache.rate(from: .usd, to: .eur) == Decimal(string: "0.95")!)
}

@Test func inMemoryClear() async {
    let cache = InMemoryRateCache(ttl: 3600)
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rateTable, for: "USD")
    await cache.clear()
    #expect(await cache.conversionTable(for: "USD") == nil)
    #expect(await cache.allBaseCurrencyCodes().isEmpty)
}

@Test func inMemoryAllBaseCurrencyCodes() async {
    let cache = InMemoryRateCache(ttl: 3600)
    await cache.store(ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!]), for: "USD")
    await cache.store(ConversionRateTable(base: .eur, rates: ["USD": Decimal(string: "1.09")!]), for: "EUR")
    let codes = await Set(cache.allBaseCurrencyCodes())
    #expect(codes == ["USD", "EUR"])
}
