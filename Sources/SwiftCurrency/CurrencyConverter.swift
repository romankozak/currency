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
    public func rate(from source: Currency, to target: Currency, forceUpdate: Bool = false) async throws -> Decimal {
        // Check cache first
        if !forceUpdate,
           let cached = cache[source.code], Date().timeIntervalSince(cached.date) < cacheDuration,
           let r = cached.rate(for: target) {
            return r
        }

        let pairRate = try await provider.fetchRate(from: source, to: target)
        // Merge the fetched pair into the existing cache entry or create a new one
        if let existing = cache[source.code] {
            var merged = existing.rates
            for (key, value) in pairRate.rates {
                merged[key] = value
            }
            cache[source.code] = ConversionRate(base: source, rates: merged, date: pairRate.date)
        } else {
            cache[source.code] = pairRate
        }

        guard let r = pairRate.rate(for: target) else {
            throw ExchangeRateError.unsupportedCurrency(target.code)
        }
        return r
    }

    /// Converts an amount from one currency to another.
    public func convert(_ amount: Decimal, from source: Currency, to target: Currency) async throws -> Decimal {
        let r = try await rate(from: source, to: target)
        return amount * r
    }

    /// Refreshes cached exchange rates.
    ///
    /// - Parameters:
    ///   - refreshCached: If `true` (the default), refetches the full rate table for every currency already in the cache.
    ///   - additionalCurrencies: Extra currencies to prefetch. Defaults to an empty list.
    /// - Throws: ``ExchangeRateError/refreshFailed(currencies:)`` if any currencies failed to fetch.
    ///           Successfully fetched currencies are still cached.
    public func refreshCache(
        refreshCached: Bool = true,
        additionalCurrencies: [Currency] = []
    ) async throws {
        var currenciesToFetch: [Currency] = additionalCurrencies

        if refreshCached {
            for code in cache.keys {
                if let currency = Currency.find(code),
                   !currenciesToFetch.contains(currency) {
                    currenciesToFetch.append(currency)
                }
            }
        }

        guard !currenciesToFetch.isEmpty else { return }

        let results = await withTaskGroup(
            of: (Currency, Result<ConversionRate, Error>).self
        ) { group in
            for currency in currenciesToFetch {
                let provider = self.provider
                group.addTask {
                    do {
                        let rates = try await provider.fetchRates(for: currency)
                        return (currency, .success(rates))
                    } catch {
                        return (currency, .failure(error))
                    }
                }
            }

            var collected: [(Currency, Result<ConversionRate, Error>)] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        var failed: [Currency] = []
        for (currency, result) in results {
            switch result {
            case .success(let rates):
                cache[currency.code] = rates
            case .failure:
                failed.append(currency)
            }
        }

        if !failed.isEmpty {
            throw ExchangeRateError.refreshFailed(currencies: failed)
        }
    }

    /// Clears the cached rates.
    public func clearCache() {
        cache.removeAll()
    }

}
