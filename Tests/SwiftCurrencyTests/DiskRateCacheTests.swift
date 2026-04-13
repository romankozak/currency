import Foundation
import Testing
@testable import SwiftCurrency

// MARK: - DiskRateCache

@Test func diskStoreAndRetrieve() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache = DiskRateCache(fileURL: url, ttl: 3600)
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rateTable, for: "USD")

    let retrieved = await cache.conversionRate(for: "USD")
    #expect(retrieved != nil)
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
}

@Test func diskPersistsAcrossInstances() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache1 = DiskRateCache(fileURL: url, ttl: 3600)
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache1.store(rateTable, for: "USD")

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
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rateTable, for: "USD")
    #expect(await cache.conversionRate(for: "USD") == nil)
}

@Test func diskExpiredAfterReload() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    // Store with a long TTL
    let cache1 = DiskRateCache(fileURL: url, ttl: 3600)
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache1.store(rateTable, for: "USD")

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
    await cache.store(ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!]), for: "USD")
    await cache.store(ConversionRateTable(base: .usd, rates: ["GBP": Decimal(string: "0.79")!]), for: "USD")

    let retrieved = await cache.conversionRate(for: "USD")
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
    #expect(retrieved!.rate(for: .gbp) == Decimal(string: "0.79")!)
}

@Test func diskClearRemovesData() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache = DiskRateCache(fileURL: url, ttl: 3600)
    await cache.store(ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!]), for: "USD")
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
