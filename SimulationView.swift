import SwiftUI
import Charts

struct SimulationView: View {
    @EnvironmentObject private var store: TradeSenseStore
    @State private var symbol = "AAPL"
    @State private var side = "BUY"
    @State private var shares = "10"
    @State private var price = ""
    @State private var note = ""
    @State private var initial = "10000"
    @State private var monthly = "300"
    @State private var years = 10.0
    @State private var annualReturn = 7.0
    @State private var startPrice = "100"
    @State private var targetPrice = "180"
    @State private var stopDistance = "2.5"
    @State private var riskPercent = "1"
    @State private var accountSize = "10000"
    @State private var simSeed = 12
    @State private var strategy = "Combined signal"
    private var compoundValue: Double {
        let principal = Double(initial) ?? 0
        let contribution = Double(monthly) ?? 0
        let rate = annualReturn / 100 / 12
        let n = Int(years * 12)
        guard n > 0 else { return principal }
        if rate == 0 { return principal + contribution * Double(n) }
        return principal * pow(1 + rate, Double(n)) + contribution * (pow(1 + rate, Double(n)) - 1) / rate
    }
    private var positionSize: Double {
        let account = Double(accountSize) ?? 0
        let risk = Double(riskPercent) ?? 0
        let distance = Double(stopDistance) ?? 0
        guard distance > 0 else { return 0 }
        return account * risk / 100 / distance
    }
    private var mcResults: [Double] {
        (0..<1000).map { i in
            let seed = Double((i * 7919 + simSeed * 104729) % 10000) / 10000
            let randomish = (seed + sin(Double(i) * 12.9898) * 0.5 + cos(Double(i) * 78.233) * 0.5)
            let annual = max(-0.8, min(0.8, annualReturn / 100 + randomish * 0.35))
            return (Double(initial) ?? 10000) * pow(1 + annual, years)
        }.sorted()
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Paper trading") {
                    LabeledContent("Virtual cash", value: store.virtualCash.formatted(.currency(code: "USD")))
                    Picker("Stock", selection: $symbol) {
                        ForEach(store.stocks) { Text($0.symbol).tag($0.symbol) }
                    }
                    Picker("Side", selection: $side) {
                        Text("BUY").tag("BUY")
                        Text("SELL").tag("SELL")
                    }.pickerStyle(.segmented)
                    TextField("Shares", text: $shares).keyboardType(.decimalPad)
                    TextField("Order price (USD)", text: $price).keyboardType(.decimalPad)
                    TextField("Journal note (optional)", text: $note)
                    Button("Place paper order") {
                        let current = store.stocks.first(where: { $0.symbol == symbol })?.price ?? 0
                        store.placePaperTrade(symbol: symbol, side: side, shares: Double(shares) ?? 0, price: Double(price) ?? current, note: note)
                        note = ""
                    }.buttonStyle(.borderedProminent)
                    Text("Orders are simulated locally. Market/limit execution, holdings reconciliation and stop orders are not connected to a broker.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Trade history") {
                    if store.trades.isEmpty {
                        Text("No paper trades yet. Place a simulated order above.").foregroundStyle(.secondary)
                    } else {
                        ForEach(store.trades) { trade in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(trade.side) \(trade.symbol)").font(.headline)
                                    Text("\(trade.shares, specifier: "%.3f") shares · \(trade.date.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary)
                                    if !trade.note.isEmpty { Text(trade.note).font(.caption).foregroundStyle(.secondary) }
                                }
                                Spacer()
                                Text((trade.shares * trade.price).formatted(.currency(code: "USD"))).font(.subheadline.bold())
                            }
                        }
                    }
                }
                Section("Compound growth calculator") {
                    moneyField("Initial investment ($)", text: $initial)
                    moneyField("Monthly contribution ($)", text: $monthly)
                    VStack(alignment: .leading) {
                        Text("Years: \(years, specifier: "%.0f")")
                        Slider(value: $years, in: 1...40, step: 1)
                        Text("Assumed annual return: \(annualReturn, specifier: "%.1f")%")
                        Slider(value: $annualReturn, in: -10...20, step: 0.5)
                    }
                    MetricTile(title: "Projected value", value: compoundValue.formatted(.currency(code: "USD")), caption: "Illustrative estimate; returns are not guaranteed.")
                }
                Section("Monte Carlo-style scenario explorer") {
                    Text("Runs: 1,000 · model: illustrative randomized annual-return scenarios")
                        .font(.caption).foregroundStyle(.secondary)
                    Chart(Array(mcResults.enumerated().filter { $0.offset % 20 == 0 }), id: \.offset) { item in
                        LineMark(x: .value("Scenario", item.offset), y: .value("Ending value", item.element))
                            .foregroundStyle(Color.green)
                    }.frame(height: 150)
                    LabeledContent("Worst scenario", value: (mcResults.first ?? 0).formatted(.currency(code: "USD")))
                    LabeledContent("Median scenario", value: (mcResults[mcResults.count / 2]).formatted(.currency(code: "USD")))
                    LabeledContent("Best scenario", value: (mcResults.last ?? 0).formatted(.currency(code: "USD")))
                    Button("Regenerate scenarios") { simSeed += 1 }
                    Text("This is a simple demonstration, not a calibrated market Monte Carlo model. It ignores volatility clustering, correlations, fees and taxes.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("What-if calculator") {
                    moneyField("Past share price ($)", text: $startPrice)
                    moneyField("Current share price ($)", text: $targetPrice)
                    let past = Double(startPrice) ?? 0
                    let current = Double(targetPrice) ?? 0
                    LabeledContent("Return", value: past > 0 ? String(format: "%+.2f%%", (current / past - 1) * 100) : "—")
                    LabeledContent("$1,000 would be", value: past > 0 ? (1000 / past * current).formatted(.currency(code: "USD")) : "—")
                }
                Section("Position sizing") {
                    moneyField("Account size ($)", text: $accountSize)
                    moneyField("Risk per trade (%)", text: $riskPercent)
                    moneyField("Stop distance ($/share)", text: $stopDistance)
                    LabeledContent("Suggested shares", value: String(format: "%.2f", positionSize))
                    LabeledContent("Dollar risk", value: ((Double(accountSize) ?? 0) * (Double(riskPercent) ?? 0) / 100).formatted(.currency(code: "USD")))
                }
                Section("Backtest preview") {
                    Picker("Strategy", selection: $strategy) {
                        Text("RSI").tag("RSI")
                        Text("MACD cross").tag("MACD cross")
                        Text("SMA cross").tag("SMA cross")
                        Text("Combined signal").tag("Combined signal")
                    }
                    Text("Selected: \(strategy)").font(.headline)
                    Text("A real historical backtester requires timestamped, split-adjusted historical data. Phase-independent preview only: this screen does not claim historical backtest metrics from generated demo prices.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden).background(Color.black)
            .navigationTitle("Simulations")
        }
    }

    private func moneyField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text).keyboardType(.decimalPad)
    }
}
