import Foundation
import Combine

private struct RateCache: Codable {
    let rates: [String: Double]
    let fetchDate: Date
}

@MainActor
final class CurrencyStore: ObservableObject {
    @Published var fromCurrency: Currency = Currency.all.first(where: { $0.code == "USD" })!
    @Published var toCurrency:   Currency = Currency.all.first(where: { $0.code == "PHP" })!
    @Published var rates:        [String: Double] = [:]
    @Published var lastUpdated:  Date? = nil
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String? = nil

    private let cacheKey        = "tb_rate_cache"
    private let refreshInterval: TimeInterval = 3_600          // 1 hour
    private let staleThreshold:  TimeInterval = 86_400         // 24 hours
    private let expiryThreshold: TimeInterval = 86_400 * 90   // 3 months

    var isRateStale: Bool {
        guard let d = lastUpdated else { return true }
        return Date().timeIntervalSince(d) > staleThreshold
    }

    var isCacheExpired: Bool {
        guard let d = lastUpdated else { return true }
        return Date().timeIntervalSince(d) > expiryThreshold
    }

    var rateDisplay: String? {
        guard let fromRate = rates[fromCurrency.code],
              let toRate   = rates[toCurrency.code],
              fromRate > 0 else { return nil }
        return "1 \(fromCurrency.code) = \(formatted(toRate / fromRate)) \(toCurrency.code)"
    }

    init() {
        loadCache()
        refreshIfNeeded()
    }

    func convert(amount: Double, from: Currency, to: Currency) -> Double? {
        guard let fromRate = rates[from.code],
              let toRate   = rates[to.code],
              fromRate > 0 else { return nil }
        return amount * toRate / fromRate
    }

    func swap() {
        Swift.swap(&fromCurrency, &toCurrency)
    }

    func refresh() {
        Task { await fetchRates() }
    }

    // MARK: - Private

    private func refreshIfNeeded() {
        guard let d = lastUpdated else { refresh(); return }
        if Date().timeIntervalSince(d) > refreshInterval { refresh() }
    }

    private func fetchRates() async {
        isRefreshing = true
        errorMessage = nil
        do {
            let response = try await ExchangeRateService.fetchRates()
            rates = response.rates
            lastUpdated = Date()
            saveCache()
        } catch {
            errorMessage = "Could not update rates."
        }
        isRefreshing = false
    }

    private func loadCache() {
        guard let data  = UserDefaults.standard.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode(RateCache.self, from: data) else { return }
        rates = cache.rates
        lastUpdated = cache.fetchDate
    }

    private func saveCache() {
        guard let data = try? JSONEncoder().encode(RateCache(rates: rates, fetchDate: lastUpdated ?? Date())) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private func formatted(_ value: Double) -> String {
        if value >= 100 { return String(format: "%.2f", value) }
        if value >= 1   { return String(format: "%.4f", value) }
        return String(format: "%.6f", value)
    }
}
