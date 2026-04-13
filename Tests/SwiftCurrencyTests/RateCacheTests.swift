import Foundation
import Testing
@testable import SwiftCurrency

// MARK: - InMemoryRateCache

@Test func inMemoryStoreAndRetrieve() async {
    let cache = InMemoryRateCache(ttl: 3600)
    let rate = ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rate, for: "USD")
    let retrieved = await cache.conversionRate(for: "USD")
    #expect(retrieved != nil)
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
}

@Test func inMemoryRateFromTo() async {
    let cache = InMemoryRateCache(ttl: 3600)
    let rate = ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rate, for: "USD")
    #expect(await cache.rate(from: .usd, to: .eur) == Decimal(string: "0.92")!)
    #expect(await cache.rate(from: .usd, to: .gbp) == nil)
}

@Test func inMemoryReturnsNilForMissing() async {
    let cache = InMemoryRateCache(ttl: 3600)
    #expect(await cache.conversionRate(for: "USD") == nil)
    #expect(await cache.rate(from: .usd, to: .eur) == nil)
}

@Test func inMemoryTTLExpiration() async {
    let cache = InMemoryRateCache(ttl: 0)
    let rate = ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rate, for: "USD")
    // TTL is 0, so it's already expired
    #expect(await cache.conversionRate(for: "USD") == nil)
    #expect(await cache.rate(from: .usd, to: .eur) == nil)
}

@Test func inMemoryMergesOnStore() async {
    let cache = InMemoryRateCache(ttl: 3600)
    let first = ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(first, for: "USD")
    let second = ConversionRate(base: .usd, rates: ["GBP": Decimal(string: "0.79")!])
    await cache.store(second, for: "USD")
    let retrieved = await cache.conversionRate(for: "USD")
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
    #expect(retrieved!.rate(for: .gbp) == Decimal(string: "0.79")!)
}

@Test func inMemoryMergeOverwritesExistingKeys() async {
    let cache = InMemoryRateCache(ttl: 3600)
    let first = ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(first, for: "USD")
    let second = ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.95")!])
    await cache.store(second, for: "USD")
    #expect(await cache.rate(from: .usd, to: .eur) == Decimal(string: "0.95")!)
}

@Test func inMemoryClear() async {
    let cache = InMemoryRateCache(ttl: 3600)
    let rate = ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rate, for: "USD")
    await cache.clear()
    #expect(await cache.conversionRate(for: "USD") == nil)
    #expect(await cache.allBaseCurrencyCodes().isEmpty)
}

@Test func inMemoryAllBaseCurrencyCodes() async {
    let cache = InMemoryRateCache(ttl: 3600)
    await cache.store(ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!]), for: "USD")
    await cache.store(ConversionRate(base: .eur, rates: ["USD": Decimal(string: "1.09")!]), for: "EUR")
    let codes = await Set(cache.allBaseCurrencyCodes())
    #expect(codes == ["USD", "EUR"])
}

// MARK: - DiskRateCache

@Test func diskStoreAndRetrieve() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache = DiskRateCache(fileURL: url, ttl: 3600)
    let rate = ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rate, for: "USD")

    let retrieved = await cache.conversionRate(for: "USD")
    #expect(retrieved != nil)
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
}

@Test func diskPersistsAcrossInstances() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache1 = DiskRateCache(fileURL: url, ttl: 3600)
    let rate = ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache1.store(rate, for: "USD")

    // New instance reads from disk
    let cache2 = DiskRateCache(fileURL: url, ttl: 3600)
    let retrieved = await cache2.conversionRate(for: "USD")
    #expect(retrieved != nil)
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
}

@Test func diskTTLExpiration() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache = DiskRateCache(fileURL: url, ttl: 0)
    let rate = ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rate, for: "USD")
    #expect(await cache.conversionRate(for: "USD") == nil)
}

@Test func diskExpiredAfterReload() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    // Store with a long TTL
    let cache1 = DiskRateCache(fileURL: url, ttl: 3600)
    let rate = ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache1.store(rate, for: "USD")

    // Reload with zero TTL — should be expired
    let cache2 = DiskRateCache(fileURL: url, ttl: 0)
    #expect(await cache2.conversionRate(for: "USD") == nil)
    // But allBaseCurrencyCodes still returns it (expired entries are still stored)
    #expect(await cache2.allBaseCurrencyCodes().contains("USD"))
}

@Test func diskMergesOnStore() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache = DiskRateCache(fileURL: url, ttl: 3600)
    await cache.store(ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!]), for: "USD")
    await cache.store(ConversionRate(base: .usd, rates: ["GBP": Decimal(string: "0.79")!]), for: "USD")

    let retrieved = await cache.conversionRate(for: "USD")
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
    #expect(retrieved!.rate(for: .gbp) == Decimal(string: "0.79")!)
}

@Test func diskClearRemovesData() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache = DiskRateCache(fileURL: url, ttl: 3600)
    await cache.store(ConversionRate(base: .usd, rates: ["EUR": Decimal(string: "0.92")!]), for: "USD")
    await cache.clear()
    #expect(await cache.conversionRate(for: "USD") == nil)

    // New instance also sees empty
    let cache2 = DiskRateCache(fileURL: url, ttl: 3600)
    #expect(await cache2.conversionRate(for: "USD") == nil)
}

@Test func diskHandlesMissingFile() async {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("nonexistent_\(UUID()).json")
    let cache = DiskRateCache(fileURL: url, ttl: 3600)
    #expect(await cache.conversionRate(for: "USD") == nil)
    #expect(await cache.allBaseCurrencyCodes().isEmpty)
}

@Test func diskHandlesCorruptFile() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    try "not valid json".data(using: .utf8)!.write(to: url)
    let cache = DiskRateCache(fileURL: url, ttl: 3600)
    #expect(await cache.conversionRate(for: "USD") == nil)
    #expect(await cache.allBaseCurrencyCodes().isEmpty)
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
