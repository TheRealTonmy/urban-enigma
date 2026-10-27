import Foundation

struct Candle: Identifiable, Codable, Hashable {
    var id: Date { date }
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

struct Stock: Identifiable, Codable, Hashable {
    var id: String { symbol }
    let symbol: String
    var name: String
    var sector: String
    var price: Double
    var changePercent: Double
    var currency: String = "USD"
    var history: [Candle]
    var pe: Double
    var eps: Double
    var revenueGrowth: Double
    var profitMargin: Double
    var debtEquity: Double
    var dividendYield: Double
    var marketCap: Double
    var weekLow: Double
    var weekHigh: Double
}

enum RiskProfile: String, CaseIterable, Codable, Identifiable {
    case low = "Low", medium = "Medium", high = "High"
    var id: String { rawValue }
    var description: String {
        switch self {
        case .low: return "Lower volatility and stricter entry thresholds."
        case .medium: return "Balanced signal sensitivity and risk."
        case .high: return "More responsive signals with higher volatility tolerance."
        }
    }
}

enum InvestmentHorizon: String, CaseIterable, Identifiable {
    case short = "Short-term", long = "Long-term"
    var id: String { rawValue }
}

enum Verdict: String, Codable {
    case buy = "BUY", hold = "HOLD", avoid = "AVOID"
}

struct IndicatorReading: Identifiable {
    let id: String
    let value: String
    let contribution: Double
    let explanation: String
}

struct Prediction: Identifiable {
    var id: String { stockSymbol + horizon.rawValue }
    let stockSymbol: String
    let verdict: Verdict
    let score: Double
    let confidence: Int
    let horizon: InvestmentHorizon
    let indicators: [IndicatorReading]
    let summary: String
}

struct NewsItem: Identifiable {
    let id = UUID()
    let headline: String
    let source: String
    let age: String
    let sentiment: Double
}
