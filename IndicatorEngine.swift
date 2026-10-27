import Foundation

struct IndicatorSnapshot {
    let rsi: Double
    let macd: Double
    let macdSignal: Double
    let sma50: Double
    let sma200: Double
    let ema20: Double
    let upperBand: Double
    let lowerBand: Double
    let atr: Double
    let stochastic: Double
    let volumeRatio: Double
    let momentum: Double
    let support: Double
    let resistance: Double
}

enum IndicatorEngine {
    static func snapshot(_ candles: [Candle]) -> IndicatorSnapshot? {
        guard candles.count >= 20 else { return nil }
        let closes = candles.map(\.close)
        let last = candles.last!
        let rsi = calculateRSI(closes, period: 14)
        let ema12 = ema(closes, period: 12)
        let ema26 = ema(closes, period: 26)
        let macdSeries = zip(ema12, ema26).map { pair in pair.0 - pair.1 }
        let macd = macdSeries.last ?? 0
        let signal = ema(macdSeries, period: 9).last ?? 0
        let sma50 = average(closes.suffix(50))
        let sma200 = average(closes.suffix(200))
        let ema20 = ema(closes, period: 20).last ?? last.close
        let recent20 = Array(closes.suffix(20))
        let mean = average(recent20)
        let variance = recent20.reduce(0) { $0 + pow($1 - mean, 2) } / Double(recent20.count)
        let sd = sqrt(variance)
        let ranges = candles.suffix(14).map { max($0.high - $0.low, abs($0.high - last.close), abs($0.low - last.close)) }
        let atr = average(ranges)
        let lows = candles.suffix(14).map(\.low).min() ?? last.low
        let highs = candles.suffix(14).map(\.high).max() ?? last.high
        let stochastic = highs > lows ? 100 * (last.close - lows) / (highs - lows) : 50
        let recentVolume = average(candles.suffix(5).map(\.volume))
        let normalVolume = average(candles.suffix(20).map(\.volume))
        let momentum = closes.count > 10 ? (last.close / closes[closes.count - 11] - 1) * 100 : 0
        return IndicatorSnapshot(
            rsi: rsi, macd: macd, macdSignal: signal,
            sma50: sma50, sma200: sma200, ema20: ema20,
            upperBand: mean + 2 * sd, lowerBand: mean - 2 * sd,
            atr: atr, stochastic: stochastic,
            volumeRatio: normalVolume > 0 ? recentVolume / normalVolume : 1,
            momentum: momentum, support: candles.suffix(30).map(\.low).min() ?? last.low,
            resistance: candles.suffix(30).map(\.high).max() ?? last.high
        )
    }

    static func average<S: Collection>(_ values: S) -> Double where S.Element == Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    static func ema(_ values: [Double], period: Int) -> [Double] {
        guard let first = values.first else { return [] }
        let multiplier = 2.0 / (Double(period) + 1)
        var result = [first]
        for value in values.dropFirst() {
            result.append(value * multiplier + result[result.count - 1] * (1 - multiplier))
        }
        return result
    }

    static func calculateRSI(_ closes: [Double], period: Int) -> Double {
        guard closes.count > period else { return 50 }
        let changes = zip(closes.dropFirst(), closes).map { pair in pair.0 - pair.1 }
        let sample = changes.suffix(period)
        let gains = sample.filter { $0 > 0 }.reduce(0, +) / Double(period)
        let losses = abs(sample.filter { $0 < 0 }.reduce(0, +)) / Double(period)
        if losses == 0 { return 100 }
        let rs = gains / losses
        return 100 - 100 / (1 + rs)
    }
}
