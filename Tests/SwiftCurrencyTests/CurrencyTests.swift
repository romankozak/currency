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
    let custom = Currency(code: "TST", symbol: "T")
    #expect(custom.minorUnits == 2)
}

@Test func currencyCustomMinorUnits() {
    let custom = Currency(code: "TST", symbol: "T", minorUnits: 5)
    #expect(custom.minorUnits == 5)
}

@Test func currencyNormalizesCode() {
    #expect(Currency(code: "usd", symbol: "$").code == "USD")
    #expect(Currency(code: " usd ", symbol: "$") == .usd)
}

@Test func currencyEquality() {
    #expect(Currency.eur == Currency.eur)
    #expect(Currency.usd != Currency.gbp)

    let copy = Currency(code: "USD", symbol: "$")
    #expect(copy == Currency.usd)
}

@Test func currencyInequalityDifferentFields() {
    let a = Currency(code: "USD", symbol: "$")
    let b = Currency(code: "USD", symbol: "US$")
    #expect(a == b)
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
