import Foundation

struct Holding: Identifiable, Codable {
    var id = UUID()
    var symbol: String
    var shares: Double
    var averageCost: Double
    var purchaseDate: Date
}

struct PaperTrade: Identifiable, Codable {
    var id = UUID()
    var symbol: String
    var side: String
    var shares: Double
    var price: Double
    var date: Date
    var note: String
}

struct AccuracyRecord: Identifiable, Codable {
    var id = UUID()
    var symbol: String
    var verdict: String
    var startPrice: Double
    var date: Date
    var grade5: Bool?
    var grade30: Bool?
    var grade90: Bool?
}

final class LocalStore {
    static let shared = LocalStore()
    private let defaults = UserDefaults.standard
    private init() {}
    func decode<T: Decodable>(_ type: T.Type, key: String, fallback: T) -> T {
        guard let data = defaults.data(forKey: key), let value = try? JSONDecoder().decode(type, from: data) else { return fallback }
        return value
    }
    func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }
}
