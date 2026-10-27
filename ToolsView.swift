import SwiftUI
import LocalAuthentication

struct ToolsView: View {
    @EnvironmentObject private var store: TradeSenseStore
    @State private var ticker = "AAPL"
    @State private var alertPrice = "250"
    @State private var alertDirection = "Above"
    @State private var amount = "1000"
    @State private var dividendYield = "3"
    @State private var years = 10.0
    @State private var monthly = "100"
    @State private var exportedURL: URL?
    @State private var showShare = false

    private let glossary: [(String, String)] = [
        ("RSI", "Relative Strength Index compares recent upward and downward price changes. Values below 30 are often called oversold; above 70 overbought."),
        ("MACD", "Moving Average Convergence Divergence compares two exponential moving averages and a signal line to estimate momentum changes."),
        ("SMA / EMA", "Simple and exponential moving averages smooth price history. Crossovers are trend-following signals and can lag."),
        ("Bollinger Bands", "Bands around a moving average widen when volatility rises and narrow when it falls."),
        ("ATR", "Average True Range estimates recent price range. It measures volatility, not direction."),
        ("Stochastic", "Compares the latest close with the recent high-low range. It can remain overbought or oversold during strong trends."),
        ("Support / resistance", "Areas where price has previously struggled to fall through or rise beyond. These are estimates, not guaranteed levels."),
        ("Sharpe ratio", "Excess return divided by return volatility. Interpretation depends on assumptions and the return series used."),
        ("Drawdown", "The decline from a previous portfolio peak to a later trough.")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Watchlist & price alerts") {
                    Picker("Stock", selection: $ticker) { ForEach(store.stocks) { Text($0.symbol).tag($0.symbol) } }
                    Picker("Alert when price is", selection: $alertDirection) {
                        Text("Above").tag("Above")
                        Text("Below").tag("Below")
                    }.pickerStyle(.segmented)
                    TextField("Price in USD", text: $alertPrice).keyboardType(.decimalPad)
                    Button("Schedule local price reminder") {
                        Task {
                            let ok = await NotificationService.requestPermission()
                            if ok {
                                NotificationService.schedule(title: "\(ticker) price reminder", body: "Review \(ticker): configured threshold \(alertDirection.lowercased()) $\(alertPrice). iOS local notifications cannot continuously monitor market prices while the app is closed.", date: Date().addingTimeInterval(60))
                                store.statusMessage = "A test reminder is scheduled for about one minute from now. It does not monitor live prices."
                            } else { store.statusMessage = "Allow notifications in iOS Settings to schedule reminders." }
                        }
                    }
                    Text("Local notifications cannot reliably check live prices in the background without a running data task or server. This button schedules a reminder, not a price-triggered alert.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("DCA calculator") {
                    TextField("Monthly contribution ($)", text: $monthly).keyboardType(.decimalPad)
                    TextField("Assumed annual dividend yield (%)", text: $dividendYield).keyboardType(.decimalPad)
                    VStack(alignment: .leading) {
                        Text("Years: \(years, specifier: "%.0f")")
                        Slider(value: $years, in: 1...40, step: 1)
                    }
                    let monthlyAmount = Double(monthly) ?? 0
                    let yieldRate = (Double(dividendYield) ?? 0) / 100 / 12
                    let months = years * 12
                    let future = yieldRate == 0 ? monthlyAmount * months : monthlyAmount * (pow(1 + yieldRate, months) - 1) / yieldRate
                    MetricTile(title: "DCA future value", value: future.formatted(.currency(code: "USD")), caption: "Simplified yield-only illustration; excludes share-price changes, fees and taxes.")
                }
                Section("Compound calculator") {
                    TextField("Starting amount ($)", text: $amount).keyboardType(.decimalPad)
                    let principal = Double(amount) ?? 0
                    let estimate = principal * pow(1.07, years)
                    LabeledContent("At 7% for \(years, specifier: "%.0f") years", value: estimate.formatted(.currency(code: "USD")))
                    Slider(value: $years, in: 1...40, step: 1)
                }
                Section("Accuracy tracker") {
                    LabeledContent("Logged verdicts", value: "\(store.accuracy.count)")
                    let graded = store.accuracy.compactMap(\.grade30)
                    LabeledContent("30-day hit rate", value: graded.isEmpty ? "Awaiting outcomes" : String(format: "%.1f%%", Double(graded.filter{$0}.count) / Double(graded.count) * 100))
                    ForEach(store.accuracy.prefix(10)) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(record.symbol) · \(record.verdict)").font(.headline)
                            Text("Logged \(record.date.formatted(date: .abbreviated, time: .omitted)) at $\(record.startPrice, specifier: "%.2f")")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("5d: \(record.grade5.map { $0 ? "Hit" : "Miss" } ?? "Pending") · 30d: \(record.grade30.map { $0 ? "Hit" : "Miss" } ?? "Pending") · 90d: \(record.grade90.map { $0 ? "Hit" : "Miss" } ?? "Pending")")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Text("Outcome grading is stored as a model for future price updates; automatic 5/30/90-day grading requires reliable historical/live data and is not yet automated.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Security & export") {
                    Toggle("Require Face ID / passcode", isOn: Binding(get: { store.faceIDEnabled }, set: { value in
                        store.faceIDEnabled = value
                        if value { store.isUnlocked = false } else { store.isUnlocked = true }
                    }))
                    Button("Test unlock") { Task { await store.unlockWithBiometrics() } }
                    Button {
                        exportedURL = store.exportCSV()
                        showShare = exportedURL != nil
                    } label: { Label("Export portfolio and trades as CSV", systemImage: "square.and.arrow.up") }
                    .disabled(store.holdings.isEmpty && store.trades.isEmpty)
                    .sheet(isPresented: $showShare) {
                        if let url = exportedURL { ShareSheet(items: [url]) }
                    }
                    Button("Enable morning digest") {
                        Task {
                            let ok = await NotificationService.requestPermission()
                            if ok { NotificationService.scheduleMorningDigest(); store.statusMessage = "Daily local reminder scheduled for 8:00 AM." }
                            else { store.statusMessage = "Notifications were not authorised." }
                        }
                    }
                }
                Section("Learn indicators") {
                    ForEach(glossary, id: \.0) { item in
                        DisclosureGroup(item.0) {
                            Text(item.1).font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 5)
                        }
                    }
                }
                Section("Data source") {
                    Toggle("Demo Mode (recommended for offline use)", isOn: $store.useDemo)
                    SecureField("Finnhub API key", text: $store.apiKey).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Picker("Risk profile", selection: $store.risk) {
                        ForEach(RiskProfile.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Button("Save settings") { store.saveSettings() }
                    Text("This complete starter uses generated demo prices. API key is stored locally. Live API wiring is not yet connected to all modules.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Disclaimer") {
                    Text("TradeSense is for educational and simulation purposes only. Demo data, heuristic scores, estimates and generated scenarios can be inaccurate. Nothing in this app is financial advice or a guarantee of future performance.")
                        .font(.footnote).foregroundStyle(.orange)
                }
            }
            .scrollContentBackground(.hidden).background(Color.black)
            .navigationTitle("More")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
