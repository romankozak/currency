import Foundation
import Testing
@testable import SwiftCurrency

// MARK: - ConversionRateTable

@Test func conversionRateSelf() {
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!, "GBP": Decimal(string: "0.79")!])
    #expect(rateTable.rate(for: .usd) == 1)
}

@Test func conversionRateForCurrency() {
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!, "GBP": Decimal(string: "0.79")!])
    #expect(rateTable.rate(for: .eur) == Decimal(string: "0.92")!)
    #expect(rateTable.rate(for: .gbp) == Decimal(string: "0.79")!)
}

@Test func conversionRateConvert() {
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    let result = rateTable.convert(100, to: .eur)
    #expect(result != nil)
    #expect(result! == 92)
}

@Test func conversionRateConvertZero() {
    let rateTable = ConversionRateTable(base: .usd, rates: ["EUR": Decimal(string: "0.92")!])
    #expect(rateTable.convert(0, to: .eur) == 0)
}

@Test func conversionRateConvertLargeAmount() {
    let rateTable = ConversionRateTable(base: .usd, rates: ["JPY": Decimal(string: "149.50")!])
    let result = rateTable.convert(1_000_000, to: .jpy)!
    #expect(result == 149_500_000)
}

@Test func conversionRateMissing() {
    let rateTable = ConversionRateTable(base: .usd, rates: [:])
    #expect(rateTable.rate(for: .eur) == nil)
    #expect(rateTable.convert(100, to: .eur) == nil)
}

@Test func conversionRateStoresDate() {
    let fixedDate = Date(timeIntervalSince1970: 1_000_000)
    let rateTable = ConversionRateTable(base: .usd, rates: [:], date: fixedDate)
    #expect(rateTable.date == fixedDate)
}
