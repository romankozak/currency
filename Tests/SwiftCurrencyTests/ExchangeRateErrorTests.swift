import Foundation
import Testing
@testable import SwiftCurrency

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

@Test func refreshFailedErrorDescription() {
    let error = ExchangeRateError.refreshFailed(currencies: [.usd, .eur])
    #expect(error.errorDescription?.contains("USD") == true)
    #expect(error.errorDescription?.contains("EUR") == true)
}
