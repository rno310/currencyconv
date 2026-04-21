import Foundation

struct ExchangeRateResponse: Decodable {
    let result: String
    let baseCode: String
    let rates: [String: Double]

    enum CodingKeys: String, CodingKey {
        case result
        case baseCode = "base_code"
        case rates
    }
}

enum ExchangeRateService {
    private static let url = URL(string: "https://open.er-api.com/v6/latest/USD")!

    static func fetchRates() async throws -> ExchangeRateResponse {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        guard decoded.result == "success" else {
            throw URLError(.badServerResponse)
        }
        return decoded
    }
}
