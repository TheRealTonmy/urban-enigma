import Foundation

enum PredictionEngine {
    static func evaluate(stock: Stock, risk: RiskProfile, horizon: InvestmentHorizon) -> Prediction {
        let snapshot = IndicatorEngine.snapshot(stock.history)
        guard let s = snapshot else {
            return Prediction(stockSymbol: stock.symbol, verdict: .hold, score: 0, confidence: 50, horizon: horizon, indicators: [], summary: "Not enough price history to calculate a signal.")
        }
        var readings: [IndicatorReading] = []
        func add(_ id: String, _ value: String, _ contribution: Double, _ reason: String) {
            readings.append(IndicatorReading(id: id, value: value, contribution: contribution, explanation: reason))
        }
        let rsiScore = s.rsi < 30 ? 1.0 : (s.rsi > 70 ? -1.0 : (s.rsi < 45 ? 0.35 : (s.rsi > 60 ? -0.25 : 0)))
        add("RSI", String(format: "%.1f", s.rsi), rsiScore * 1.4, s.rsi < 30 ? "RSI is oversold, which can precede a rebound but is not a guarantee." : (s.rsi > 70 ? "RSI is overbought, so pullback risk may be elevated." : "RSI is in a more neutral range."))
        let macdScore = s.macd > s.macdSignal ? 0.8 : -0.65
        add("MACD", String(format: "%.2f", s.macd), macdScore, macdScore > 0 ? "MACD is above its signal line, suggesting positive momentum." : "MACD is below its signal line, suggesting weakening momentum.")
        let crossScore = s.sma50 > s.sma200 ? 1.0 : -0.8
        add("SMA 50/200", s.sma50 > s.sma200 ? "Golden cross" : "Death cross", crossScore, s.sma50 > s.sma200 ? "The 50-day average is above the 200-day average." : "The 50-day average is below the 200-day average.")
        let bandScore = stock.price < s.lowerBand ? 0.6 : (stock.price > s.upperBand ? -0.6 : 0)
        add("Bollinger Bands", String(format: "$%.2f–$%.2f", s.lowerBand, s.upperBand), bandScore, bandScore > 0 ? "Price is below the lower band; mean reversion is possible." : (bandScore < 0 ? "Price is above the upper band; short-term stretch risk is elevated." : "Price is inside the bands."))
        let stochScore = s.stochastic < 20 ? 0.5 : (s.stochastic > 80 ? -0.5 : 0)
        add("Stochastic", String(format: "%.1f", s.stochastic), stochScore, s.stochastic < 20 ? "Stochastic is oversold." : (s.stochastic > 80 ? "Stochastic is overbought." : "Stochastic is between common extremes."))
        let volumeScore = s.volumeRatio > 1.25 && s.momentum > 0 ? 0.45 : (s.volumeRatio > 1.25 && s.momentum < 0 ? -0.45 : 0)
        add("Volume trend", String(format: "%.2fx", s.volumeRatio), volumeScore, s.volumeRatio > 1.25 ? "Recent volume is elevated, confirming the current move direction." : "Recent volume is close to its recent average.")
        let momentumScore = max(-1, min(1, s.momentum / 5))
        add("Momentum", String(format: "%+.2f%%", s.momentum), momentumScore, s.momentum >= 0 ? "Recent price momentum is positive." : "Recent price momentum is negative.")
        let atrPct = stock.price > 0 ? s.atr / stock.price * 100 : 0
        add("ATR risk", String(format: "%.2f%% of price", atrPct), atrPct > 5 ? -0.25 : 0.1, atrPct > 5 ? "Recent trading range is large relative to price." : "Recent average range is comparatively contained.")
        if horizon == .long {
            let fundamental = stock.pe > 0 && stock.profitMargin > 0.12 && stock.revenueGrowth > 0 ? 0.65 : -0.35
            add("Fundamentals", String(format: "P/E %.1f · growth %.1f%%", stock.pe, stock.revenueGrowth * 100), fundamental, fundamental > 0 ? "Demo fundamentals show positive growth and a healthy profit margin." : "Demo fundamentals are mixed; review valuation, debt and growth.")
        }
        let raw = readings.reduce(0) { $0 + $1.contribution }
        let threshold: Double = risk == .low ? 2.0 : (risk == .medium ? 1.35 : 0.85)
        let verdict: Verdict = raw >= threshold ? .buy : (raw <= -threshold ? .avoid : .hold)
        let confidence = min(92, max(51, Int(50 + min(42, abs(raw) * 10))))
        let summary: String
        switch verdict {
        case .buy: summary = "The weighted indicators lean bullish. Confirm the data, timeframe and downside risk before acting."
        case .hold: summary = "Signals are mixed or below the chosen risk threshold. Waiting for confirmation may reduce false signals."
        case .avoid: summary = "The weighted indicators lean bearish. Review the reasons and consider downside exposure."
        }
        return Prediction(stockSymbol: stock.symbol, verdict: verdict, score: raw, confidence: confidence, horizon: horizon, indicators: readings, summary: summary)
    }
}
