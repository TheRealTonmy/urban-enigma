import Foundation

enum DemoData {
    static let symbols: [(String, String, String, Double, Double)] = [
        ("AAPL", "Apple", "Technology", 232.15, 1.28),
        ("MSFT", "Microsoft", "Technology", 521.40, 0.64),
        ("NVDA", "NVIDIA", "Technology", 187.32, 2.31),
        ("AMZN", "Amazon", "Consumer Discretionary", 226.85, -0.72),
        ("GOOGL", "Alphabet", "Communication Services", 248.60, 0.43),
        ("TSLA", "Tesla", "Consumer Discretionary", 431.20, -1.86),
        ("SPY", "SPDR S&P 500 ETF", "ETF", 681.55, 0.38),
        ("QQQ", "Invesco QQQ ETF", "ETF", 612.90, 0.51),
        ("DIA", "SPDR Dow Jones ETF", "ETF", 474.20, 0.21),
        ("IWM", "Russell 2000 ETF", "ETF", 241.20, -0.18),
        ("KO", "Coca-Cola", "Consumer Staples", 71.42, 0.17),
        ("JPM", "JPMorgan Chase", "Financials", 309.70, -0.22),
        ("XOM", "Exxon Mobil", "Energy", 117.45, 0.32),
        ("JNJ", "Johnson & Johnson", "Healthcare", 168.20, -0.14),
        ("V", "Visa", "Financials", 351.60, 0.77)
    ]

    static func makeStocks() -> [Stock] {
        symbols.map { symbol, name, sector, price, change in
            let seed = abs(symbol.hashValue % 29) + 5
            let history: [Candle] = (0..<260).map { i in
                let date = Calendar.current.date(byAdding: .day, value: i - 259, to: Date()) ?? Date()
                let trend = (Double(i) - 130) * 0.0007
                let wave = sin(Double(i + seed) / 7.0) * 0.035 + cos(Double(i + seed) / 17.0) * 0.018
                let close = max(1, price * (1 + trend + wave))
                let previous = i == 0 ? close * 0.995 : max(1, price * (1 + (Double(i - 1) - 130) * 0.0007 + sin(Double(i - 1 + seed) / 7.0) * 0.035 + cos(Double(i - 1 + seed) / 17.0) * 0.018))
                let high = max(close, previous) * (1 + 0.006 + Double((i + seed) % 5) / 1000)
                let low = min(close, previous) * (1 - 0.006 - Double((i + seed) % 4) / 1000)
                return Candle(date: date, open: previous, high: high, low: low, close: close, volume: 1_000_000 + Double((i * 37 + seed * 113) % 1_700_000))
            }
            let factor = Double(abs(symbol.hashValue % 11) + 1)
            return Stock(
                symbol: symbol, name: name, sector: sector, price: price,
                changePercent: change, history: history,
                pe: 12 + factor * 2.7, eps: price / max(1, 12 + factor * 2.7),
                revenueGrowth: (Double(symbol.hashValue % 21) - 4) / 100,
                profitMargin: 0.08 + factor / 100,
                debtEquity: 0.2 + factor / 8,
                dividendYield: ["KO", "JNJ", "JPM", "XOM"].contains(symbol) ? 0.025 + factor / 1000 : 0.003,
                marketCap: price * (10_000_000_000 + factor * 1_000_000_000),
                weekLow: price * 0.72, weekHigh: price * 1.18
            )
        }
    }

    static let news: [String: [NewsItem]] = [
        "AAPL": [
            NewsItem(headline: "Product ecosystem remains a key driver of services revenue", source: "Demo Market Brief", age: "2h", sentiment: 0.55),
            NewsItem(headline: "Investors watch demand trends ahead of earnings", source: "Demo Market Brief", age: "5h", sentiment: 0.05)
        ],
        "NVDA": [
            NewsItem(headline: "AI infrastructure spending supports sector optimism", source: "Demo Market Brief", age: "1h", sentiment: 0.72),
            NewsItem(headline: "Competition and valuation remain key risks", source: "Demo Market Brief", age: "4h", sentiment: -0.35)
        ]
    ]
}
