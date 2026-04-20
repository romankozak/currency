import Foundation
import Testing
@testable import SwiftCurrency

// MARK: - LocalFileRateCache

@Test func diskStoreAndRetrieve() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache = LocalFileRateCache(fileURL: url)
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache.store(rateTable, for: "USD")

    let retrieved = await cache.conversionTable(for: "USD")
    #expect(retrieved != nil)
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
}

@Test func diskPersistsAcrossInstances() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache1 = LocalFileRateCache(fileURL: url)
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    await cache1.store(rateTable, for: "USD")

    // New instance reads from disk
    let cache2 = LocalFileRateCache(fileURL: url)
    let retrieved = await cache2.conversionTable(for: "USD")
    #expect(retrieved != nil)
    #expect(retrieved!.rate(for: .eur) == Decimal(string: "0.92")!)
}

@Test func diskAlwaysReturnsStaleData() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache = LocalFileRateCache(fileURL: url)
    let staleTable = ConversionRateTable(
        base: .usd,
        rates: ["EUR": Decimal(string: "0.92")!],
        date: Date(timeIntervalSinceNow: -86400)  // 1 day old
    )
    await cache.store(staleTable, for: "USD")
    // Cache has no TTL — stale data is always returned
    #expect(await cache.conversionTable(for: "USD") != nil)
}

@Test func diskMergesOnStore() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache = LocalFileRateCache(fileURL: url)
    await cache.store(ConversionRateTable(base: .usd, rates: ["EUR": Decimal(0.92)]), for: "USD")
    await cache.store(ConversionRateTable(base: .usd, rates: ["GBP": Decimal(0.79)]), for: "USD")

    let retrieved = await cache.conversionTable(for: "USD")
    #expect(retrieved!.rate(for: .eur) == Decimal(0.92))
    #expect(retrieved!.rate(for: .gbp) == Decimal(0.79))
}

@Test func diskClearRemovesData() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let cache = LocalFileRateCache(fileURL: url)
    await cache.store(ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!]), for: "USD")
    await cache.clear()
    #expect(await cache.conversionTable(for: "USD") == nil)

    // New instance also sees empty
    let cache2 = LocalFileRateCache(fileURL: url)
    #expect(await cache2.conversionTable(for: "USD") == nil)
}

@Test func diskHandlesMissingFile() async {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("nonexistent_\(UUID()).json")
    let cache = LocalFileRateCache(fileURL: url)
    #expect(await cache.conversionTable(for: "USD") == nil)
    #expect(await cache.availableCurrencyCodes().isEmpty)
}

@Test func diskHandlesCorruptFile() async throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }

    try "not valid json".data(using: .utf8)!.write(to: url)
    let cache = LocalFileRateCache(fileURL: url)
    #expect(await cache.conversionTable(for: "USD") == nil)
    #expect(await cache.availableCurrencyCodes().isEmpty)
}
