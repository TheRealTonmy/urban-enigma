import Foundation
import SwiftUI
import LocalAuthentication

@MainActor
final class TradeSenseStore: ObservableObject {
    @Published var stocks: [Stock] = DemoData.makeStocks()
    @Published var watchlist: [String] = ["AAPL", "MSFT", "NVDA", "SPY", "QQQ"]
    @Published var risk: RiskProfile = .medium
    @Published var horizon: InvestmentHorizon = .short
    @Published var searchText = ""
    @Published var selectedSymbol = "AAPL"
    @Published var apiKey = ""
    @Published var useDemo = true
    @Published var holdings: [Holding] = []
    @Published var trades: [PaperTrade] = []
    @Published var accuracy: [AccuracyRecord] = []
    @Published var virtualCash: Double = 100_000
    @Published var alertsEnabled = false
    @Published var faceIDEnabled = false
    @Published var isUnlocked = true
    @Published var statusMessage: String?

    init() {
        watchlist = UserDefaults.standard.stringArray(forKey: "ts.watchlist") ?? watchlist
        risk = RiskProfile(rawValue: UserDefaults.standard.string(forKey: "ts.risk") ?? "") ?? .medium
        apiKey = UserDefaults.standard.string(forKey: "ts.key") ?? ""
        useDemo = UserDefaults.standard.object(forKey: "ts.demo") == nil ? true : UserDefaults.standard.bool(forKey: "ts.demo")
        holdings = LocalStore.shared.decode([Holding].self, key: "ts.holdings", fallback: [])
        trades = LocalStore.shared.decode([PaperTrade].self, key: "ts.trades", fallback: [])
        accuracy = LocalStore.shared.decode([AccuracyRecord].self, key: "ts.accuracy", fallback: [])
        virtualCash = UserDefaults.standard.object(forKey: "ts.cash") == nil ? 100_000 : UserDefaults.standard.double(forKey: "ts.cash")
    }

    var selectedStock: Stock { stocks.first(where: { $0.symbol == selectedSymbol }) ?? stocks[0] }
    var watchlistStocks: [Stock] {
        stocks.filter { watchlist.contains($0.symbol) }.sorted {
            (watchlist.firstIndex(of: $0.symbol) ?? 99) < (watchlist.firstIndex(of: $1.symbol) ?? 99)
        }
    }
    var filteredStocks: [Stock] {
        guard !searchText.isEmpty else { return stocks }
        return stocks.filter { $0.symbol.localizedCaseInsensitiveContains(searchText) || $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    var portfolioValue: Double {
        holdings.reduce(0) { total, holding in
            total + holding.shares * (stocks.first(where: { stock in stock.symbol == holding.symbol })?.price ?? holding.averageCost)
        }
    }
    var portfolioCost: Double { holdings.reduce(0) { total, holding in total + holding.shares * holding.averageCost } }
    var portfolioGain: Double { portfolioValue - portfolioCost }
    var equity: Double {
        virtualCash + trades.reduce(0) { total, trade in
            total + (trade.side == "BUY" ? -trade.shares * trade.price : trade.shares * trade.price)
        }
    }

    func prediction(for stock: Stock, horizon: InvestmentHorizon? = nil) -> Prediction {
        PredictionEngine.evaluate(stock: stock, risk: risk, horizon: horizon ?? self.horizon)
    }
    func addToWatchlist(_ symbol: String) {
        guard !watchlist.contains(symbol) else { return }
        watchlist.append(symbol)
        UserDefaults.standard.set(watchlist, forKey: "ts.watchlist")
    }
    func removeFromWatchlist(_ symbol: String) {
        watchlist.removeAll { $0 == symbol }
        UserDefaults.standard.set(watchlist, forKey: "ts.watchlist")
    }
    func saveSettings() {
        UserDefaults.standard.set(risk.rawValue, forKey: "ts.risk")
        UserDefaults.standard.set(apiKey, forKey: "ts.key")
        UserDefaults.standard.set(useDemo, forKey: "ts.demo")
        statusMessage = "Settings saved on this device."
    }
    func addHolding(symbol: String, shares: Double, cost: Double, date: Date) {
        holdings.append(Holding(symbol: symbol.uppercased(), shares: shares, averageCost: cost, purchaseDate: date))
        LocalStore.shared.save(holdings, key: "ts.holdings")
    }
    func deleteHolding(_ holding: Holding) {
        holdings.removeAll { $0.id == holding.id }
        LocalStore.shared.save(holdings, key: "ts.holdings")
    }
    func placePaperTrade(symbol: String, side: String, shares: Double, price: Double, note: String) {
        guard shares > 0, price > 0 else { statusMessage = "Enter a positive quantity and price."; return }
        let cost = shares * price
        if side == "BUY" && cost > virtualCash { statusMessage = "Not enough virtual cash for this order."; return }
        virtualCash += side == "BUY" ? -cost : cost
        trades.insert(PaperTrade(symbol: symbol, side: side, shares: shares, price: price, date: Date(), note: note), at: 0)
        UserDefaults.standard.set(virtualCash, forKey: "ts.cash")
        LocalStore.shared.save(trades, key: "ts.trades")
        statusMessage = "Paper order recorded."
    }
    func logPrediction(_ prediction: Prediction, price: Double) {
        accuracy.insert(AccuracyRecord(symbol: prediction.stockSymbol, verdict: prediction.verdict.rawValue, startPrice: price, date: Date()), at: 0)
        LocalStore.shared.save(accuracy, key: "ts.accuracy")
        statusMessage = "Prediction logged for future review."
    }
    func requestAlerts() async {
        alertsEnabled = await NotificationService.requestPermission()
        if alertsEnabled { NotificationService.scheduleMorningDigest() }
        statusMessage = alertsEnabled ? "Local notifications enabled." : "Notifications were not authorised in iOS Settings."
    }
    func unlockWithBiometrics() async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            statusMessage = "Face ID/passcode authentication is unavailable on this device."
            return
        }
        do {
            isUnlocked = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock TradeSense")
        } catch {
            isUnlocked = false
            statusMessage = "Authentication was cancelled or failed."
        }
    }
    func exportCSV() -> URL? {
        let header = "Type,Symbol,Shares,Price,Date,Note\n"
        let rows = trades.map { "Trade,\($0.symbol),\($0.shares),\($0.price),\($0.date.ISO8601Format()),\"\($0.note.replacingOccurrences(of: "\"", with: "\"\""))\"" }
        let holdingRows = holdings.map { "Holding,\($0.symbol),\($0.shares),\($0.averageCost),\($0.purchaseDate.ISO8601Format()),Real holding" }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("TradeSense-export.csv")
        do {
            try (header + (rows + holdingRows).joined(separator: "\n")).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            statusMessage = "CSV export failed."
            return nil
        }
    }
}
