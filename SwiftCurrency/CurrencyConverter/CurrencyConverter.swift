import Foundation

/// A convenience wrapper around an ``ExchangeRateProvider`` with built-in caching.
///
/// ```swift
/// let converter = CurrencyConverter()  // uses local stubbed data
/// let rate = try await converter.rate(from: .usd, to: .eur)
/// let amount = try await converter.convert(100, from: .usd, to: .gbp)
/// ```
public actor CurrencyConverter {
    private let provider: ExchangeRateProviding
    private let rateCache: any RateCaching

    /// Creates a converter with an in-memory cache.
    /// - Parameters:
    ///   - provider: The exchange rate data source. Defaults to ``LocalExchangeRateProvider``.
    ///   - cacheDuration: How long fetched rates are cached, in seconds. Defaults to 1 hour.
    public init(provider: ExchangeRateProviding = LocalExchangeRateProvider(), cacheDuration: TimeInterval = 3600) {
        self.provider = provider
        self.rateCache = InMemoryRateCache(ttl: cacheDuration)
    }

    /// Creates a converter with an explicit cache implementation.
    /// - Parameters:
    ///   - provider: The exchange rate data source. Defaults to ``LocalExchangeRateProvider``.
    ///   - cache: The cache to use for storing fetched rates.
    public init(provider: ExchangeRateProviding = LocalExchangeRateProvider(), cache: any RateCaching) {
        self.provider = provider
        self.rateCache = cache
    }

    /// Returns the exchange rate from one currency to another.
    ///
    /// Uses the provider's single-pair endpoint when available, falling back to cached full rates.
    public func rate(from source: Currency, to target: Currency, forceUpdate: Bool = false) async throws -> Decimal {
        if !forceUpdate, let r = await rateCache.rate(from: source, to: target) {
            return r
        }

        let rateTable = try await provider.fetchRate(from: source, to: target)
        await rateCache.store(rateTable, for: source.code)

        guard let r = rateTable.rate(for: target) else {
            throw ExchangeRateError.unsupportedCurrency(target.code)
        }
        return r
    }

    /// Converts an amount from one currency to another.
    public func convert(_ amount: Decimal, from source: Currency, to target: Currency) async throws -> Decimal {
        let r = try await rate(from: source, to: target)
        return amount * r
    }

    /// Refetches the full rate table for every currency already in the cache.
    ///
    /// - Throws: ``ExchangeRateError/refreshFailed(currencies:)`` if any currencies failed to fetch.
    ///           Successfully fetched currencies are still cached.
    public func refreshCache() async throws {
        let currencies = await rateCache.availableCurrencyCodes().compactMap(Currency.find)
        try await fetchAndCache(currencies)
    }

    /// Fetches and caches rate tables for the given currencies.
    ///
    /// - Parameter currencies: The currencies to prefetch.
    /// - Throws: ``ExchangeRateError/refreshFailed(currencies:)`` if any currencies failed to fetch.
    ///           Successfully fetched currencies are still cached.
    public func prefetchCurrencies(_ currencies: [Currency]) async throws {
        try await fetchAndCache(currencies)
    }

    private func fetchAndCache(_ currencies: [Currency]) async throws {
        guard !currencies.isEmpty else { return }

        let results = await withTaskGroup(
            of: (Currency, Result<ConversionRateTable, Error>).self
        ) { group in
            for currency in currencies {
                let provider = self.provider
                group.addTask {
                    do {
                        let rateTable = try await provider.fetchRates(for: currency)
                        return (currency, .success(rateTable))
                    } catch {
                        return (currency, .failure(error))
                    }
                }
            }

            var collected: [(Currency, Result<ConversionRateTable, Error>)] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        var failed: [Currency] = []
        for (currency, result) in results {
            switch result {
            case .success(let rateTable):
                await rateCache.store(rateTable, for: currency.code)
            case .failure:
                failed.append(currency)
            }
        }

        if !failed.isEmpty {
            throw ExchangeRateError.refreshFailed(currencies: failed)
        }
    }

    /// Clears the cached rates.
    public func clearCache() async {
        await rateCache.clear()
    }

}
