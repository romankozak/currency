import Foundation
import Testing
@testable import SwiftCurrency

// MARK: - InMemoryRateCache

@Test func inMemoryStoreAndRetrieve() async {
    let cache = InMemoryRateCache()
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rateTable)
    let retrieved = await cache.conversionTable(for: "USD")
    #expect(retrieved != nil)
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
}

@Test func inMemoryRateFromTo() async {
    let cache = InMemoryRateCache()
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rateTable)
    #expect(await cache.rate(from: .usd, to: .eur) == Decimal(string: "0.92")!)
    #expect(await cache.rate(from: .usd, to: .gbp) == nil)
}

@Test func inMemoryReturnsNilForMissing() async {
    let cache = InMemoryRateCache()
    #expect(await cache.conversionTable(for: "USD") == nil)
    #expect(await cache.rate(from: .usd, to: .eur) == nil)
}

@Test func inMemoryAlwaysReturnsStaleData() async {
    let cache = InMemoryRateCache()
    let staleTable = ConversionRateTable(
        base: .usd,
        rates: ["EUR": Decimal(string: "0.92")!],
        date: Date(timeIntervalSinceNow: -86400)  // 1 day old
    )
    await cache.store(staleTable)
    // Cache has no TTL — stale data is always returned
    let retrieved = await cache.conversionTable(for: "USD")
    #expect(retrieved != nil)
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
}

@Test func inMemoryMergesOnStore() async {
    let cache = InMemoryRateCache()
    let first = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(first)
    let second = ConversionRateTable(base: .usd, rates: ["GBP": Decimal(string: "0.79")!])
    await cache.store(second)
    let retrieved = await cache.conversionTable(for: "USD")
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
    #expect(retrieved!.rate(for: .gbp) == Decimal(string: "0.79")!)
}

@Test func inMemoryMergeOverwritesExistingKeys() async {
    let cache = InMemoryRateCache()
    let first = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(first)
    let second = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.95")!])
    await cache.store(second)
    #expect(await cache.rate(from: .usd, to: .eur) == Decimal(string: "0.95")!)
}

@Test func inMemoryClear() async {
    let cache = InMemoryRateCache()
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rateTable)
    await cache.clear()
    #expect(await cache.conversionTable(for: "USD") == nil)
    #expect(await cache.availableCurrencyCodes().isEmpty)
}

@Test func inMemoryAllBaseCurrencyCodes() async {
    let cache = InMemoryRateCache()
    await cache.store(ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!]))
    await cache.store(ConversionRateTable(base: .eur, rates: ["USD": Decimal(string: "1.09")!]))
    let codes = await Set(cache.availableCurrencyCodes())
    #expect(codes == ["USD", "EUR"])
}
