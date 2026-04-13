import Foundation

/// A convenience wrapper around an ``ExchangeRateProvider`` with built-in caching.
///
/// ```swift
/// let converter = CurrencyConverter()  // uses local stubbed data
/// let rate = try await converter.rate(from: .usd, to: .eur)
/// let amount = try await converter.convert(100, from: .usd, to: .gbp)
/// ```
public actor CurrencyConverter {
    private let provider: ExchangeRateProvider
    private var cache: [String: ConversionRate] = [:]
    private let cacheDuration: TimeInterval

    /// Creates a converter.
    /// - Parameters:
    ///   - provider: The exchange rate data source. Defaults to ``LocalExchangeRateProvider``.
    ///   - cacheDuration: How long fetched rates are cached, in seconds. Defaults to 1 hour.
    public init(provider: ExchangeRateProvider = LocalExchangeRateProvider(), cacheDuration: TimeInterval = 3600) {
        self.provider = provider
        self.cacheDuration = cacheDuration
    }

    /// Returns the exchange rate from one currency to another.
    ///
    /// Uses the provider's single-pair endpoint when available, falling back to cached full rates.
    public func rate(from source: Currency, to target: Currency) async throws -> Double {
        // Check cache first
        if let cached = cache[source.code], Date().timeIntervalSince(cached.date) < cacheDuration,
           let r = cached.rate(for: target) {
            return r
        }

        let pairRate = try await provider.fetchRate(from: source, to: target)
        guard let r = pairRate.rate(for: target) else {
            throw ExchangeRateError.unsupportedCurrency(target.code)
        }
        return r
    }

    /// Converts an amount from one currency to another.
    public func convert(_ amount: Double, from source: Currency, to target: Currency) async throws -> Double {
        let r = try await rate(from: source, to: target)
        return amount * r
    }

    /// Clears the cached rates.
    public func clearCache() {
        cache.removeAll()
    }

    private func getRates(for base: Currency) async throws -> ConversionRate {
        if let cached = cache[base.code], Date().timeIntervalSince(cached.date) < cacheDuration {
            return cached
        }
        let rates = try await provider.fetchRates(for: base)
        cache[base.code] = rates
        return rates
    }
}
