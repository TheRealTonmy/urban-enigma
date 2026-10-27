import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject private var store: TradeSenseStore
    @State private var search = ""
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Horizon", selection: $store.horizon) {
                        ForEach(InvestmentHorizon.allCases) { horizon in Text(horizon.rawValue).tag(horizon) }
                    }.pickerStyle(.segmented)
                    Picker("Risk profile", selection: $store.risk) {
                        ForEach(RiskProfile.allCases) { risk in Text(risk.rawValue).tag(risk) }
                    }.pickerStyle(.segmented)
                    TextField("Search ticker or company", text: $search)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                }
                Section("Signal scanner") {
                    ForEach(store.stocks.filter { search.isEmpty || $0.symbol.localizedCaseInsensitiveContains(search) || $0.name.localizedCaseInsensitiveContains(search) }) { stock in
                        NavigationLink { StockDetailView(stock: stock) } label: {
                            let p = store.prediction(for: stock)
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stock.symbol).font(.headline)
                                    Text("Score \(p.score, specifier: "%+.2f") · \(p.confidence)% confidence").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                VerdictBadge(verdict: p.verdict)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                Section {
                    Text("Signal scores are heuristic outputs from generated demo price history. Confidence is a score-strength estimate, not a statistically validated probability of profit.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden).background(Color.black)
            .navigationTitle("Analysis")
        }
    }
}

struct StockDetailView: View {
    @EnvironmentObject private var store: TradeSenseStore
    let stock: Stock
    @State private var horizon: InvestmentHorizon = .short
    @State private var showingLog = false
    var body: some View {
        let prediction = store.prediction(for: stock, horizon: horizon)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                DisclaimerBanner()
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(stock.symbol).font(.largeTitle.bold())
                        Text(stock.name).foregroundStyle(.secondary)
                        Text(stock.price, format: .currency(code: stock.currency)).font(.title.bold())
                        Text("\(stock.changePercent, specifier: "%+.2f")% today")
                            .foregroundStyle(stock.changePercent >= 0 ? .green : .red)
                    }
                    Spacer()
                    Button {
                        store.watchlist.contains(stock.symbol) ? store.removeFromWatchlist(stock.symbol) : store.addToWatchlist(stock.symbol)
                    } label: {
                        Image(systemName: store.watchlist.contains(stock.symbol) ? "star.fill" : "star")
                            .font(.title2).padding(12).background(Color.white.opacity(0.07), in: Circle())
                    }
                }
                PriceLineChart(stock: stock)
                Picker("Horizon", selection: $horizon) {
                    ForEach(InvestmentHorizon.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("ENGINE VERDICT").font(.caption.bold()).foregroundStyle(.secondary)
                        Text(prediction.verdict.rawValue).font(.system(size: 34, weight: .heavy)).foregroundStyle(prediction.verdict == .buy ? .green : (prediction.verdict == .avoid ? .red : .yellow))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("\(prediction.confidence)%").font(.title.bold())
                        Text("signal strength").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text(prediction.summary).font(.subheadline)
                Button {
                    store.logPrediction(prediction, price: stock.price)
                    showingLog = true
                } label: {
                    Label("Log this verdict for accuracy tracking", systemImage: "checkmark.seal")
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                }.buttonStyle(.borderedProminent)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Why this signal?").font(.title3.bold())
                    ForEach(prediction.indicators) { indicator in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(indicator.id).font(.headline)
                                Spacer()
                                Text(indicator.value).font(.subheadline.monospacedDigit()).foregroundStyle(.green)
                                Text(indicator.contribution, format: .number.precision(.significantDigits(2)))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(indicator.contribution >= 0 ? .green : .red)
                            }
                            Text(indicator.explanation).font(.caption).foregroundStyle(.secondary)
                            Divider().overlay(Color.white.opacity(0.06))
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fundamentals (demo estimates)").font(.title3.bold())
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        MetricTile(title: "P/E", value: String(format: "%.1f", stock.pe), caption: "Price / earnings")
                        MetricTile(title: "EPS", value: String(format: "$%.2f", stock.eps), caption: "Earnings per share")
                        MetricTile(title: "Revenue growth", value: String(format: "%.1f%%", stock.revenueGrowth * 100), caption: "Year over year")
                        MetricTile(title: "Profit margin", value: String(format: "%.1f%%", stock.profitMargin * 100), caption: "Net margin")
                        MetricTile(title: "Debt/equity", value: String(format: "%.2f", stock.debtEquity), caption: "Leverage ratio")
                        MetricTile(title: "Dividend yield", value: String(format: "%.2f%%", stock.dividendYield * 100), caption: "Annual yield")
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("News sentiment (demo)").font(.title3.bold())
                    ForEach(DemoData.news[stock.symbol] ?? [
                        NewsItem(headline: "No stock-specific demo headlines available; live news is not connected.", source: "TradeSense", age: "—", sentiment: 0)
                    ]) { item in
                        HStack(alignment: .top) {
                            Image(systemName: item.sentiment > 0.2 ? "arrow.up.right.circle.fill" : (item.sentiment < -0.2 ? "arrow.down.right.circle.fill" : "minus.circle.fill"))
                                .foregroundStyle(item.sentiment > 0.2 ? .green : (item.sentiment < -0.2 ? .red : .yellow))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.headline).font(.subheadline)
                                Text("\(item.source) · \(item.age) · sentiment \(item.sentiment, specifier: "%+.2f")").font(.caption).foregroundStyle(.secondary)
                            }
                        }.padding(12).background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }.padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(stock.symbol).navigationBarTitleDisplayMode(.inline)
        .alert("Prediction logged", isPresented: $showingLog) { Button("OK", role: .cancel) {} } message: { Text("TradeSense will keep this verdict as a baseline. Accuracy grading needs future price observations; this demo build does not fetch those automatically yet.") }
    }
}
