import Foundation

struct Currency: Identifiable, Hashable, Equatable, Codable {
    let code: String
    let name: String
    let flag: String

    var id: String { code }
}

extension Currency {
    static let all: [Currency] = [
        Currency(code: "USD", name: "US Dollar",             flag: "🇺🇸"),
        Currency(code: "EUR", name: "Euro",                  flag: "🇪🇺"),
        Currency(code: "GBP", name: "British Pound",         flag: "🇬🇧"),
        Currency(code: "JPY", name: "Japanese Yen",          flag: "🇯🇵"),
        Currency(code: "CHF", name: "Swiss Franc",           flag: "🇨🇭"),
        Currency(code: "AUD", name: "Australian Dollar",     flag: "🇦🇺"),
        Currency(code: "CAD", name: "Canadian Dollar",       flag: "🇨🇦"),
        Currency(code: "CNY", name: "Chinese Yuan",          flag: "🇨🇳"),
        Currency(code: "HKD", name: "Hong Kong Dollar",      flag: "🇭🇰"),
        Currency(code: "SGD", name: "Singapore Dollar",      flag: "🇸🇬"),
        Currency(code: "PHP", name: "Philippine Peso",       flag: "🇵🇭"),
        Currency(code: "THB", name: "Thai Baht",             flag: "🇹🇭"),
        Currency(code: "MXN", name: "Mexican Peso",          flag: "🇲🇽"),
        Currency(code: "BRL", name: "Brazilian Real",        flag: "🇧🇷"),
        Currency(code: "INR", name: "Indian Rupee",          flag: "🇮🇳"),
        Currency(code: "KRW", name: "South Korean Won",      flag: "🇰🇷"),
        Currency(code: "NZD", name: "New Zealand Dollar",    flag: "🇳🇿"),
        Currency(code: "ZAR", name: "South African Rand",    flag: "🇿🇦"),
        Currency(code: "SEK", name: "Swedish Krona",         flag: "🇸🇪"),
        Currency(code: "NOK", name: "Norwegian Krone",       flag: "🇳🇴"),
        Currency(code: "DKK", name: "Danish Krone",          flag: "🇩🇰"),
        Currency(code: "AED", name: "UAE Dirham",            flag: "🇦🇪"),
        Currency(code: "SAR", name: "Saudi Riyal",           flag: "🇸🇦"),
        Currency(code: "TRY", name: "Turkish Lira",          flag: "🇹🇷"),
        Currency(code: "IDR", name: "Indonesian Rupiah",     flag: "🇮🇩"),
        Currency(code: "MYR", name: "Malaysian Ringgit",     flag: "🇲🇾"),
        Currency(code: "CZK", name: "Czech Koruna",          flag: "🇨🇿"),
        Currency(code: "PLN", name: "Polish Złoty",          flag: "🇵🇱"),
        Currency(code: "HUF", name: "Hungarian Forint",      flag: "🇭🇺"),
        Currency(code: "ILS", name: "Israeli Shekel",        flag: "🇮🇱"),
    ]
}
