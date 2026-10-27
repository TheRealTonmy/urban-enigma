import SwiftUI
import Charts

struct PortfolioView: View {
    @EnvironmentObject private var store: TradeSenseStore
    @State private var symbol = "AAPL"
    @State private var shares = "5"
    @State private var cost = ""
    @State private var date = Date()
    var body: some View {
        NavigationStack {
            List {
                Section("Portfolio summary") {
                    LabeledContent("Market value", value: store.portfolioValue.formatted(.currency(code: "USD")))
                    LabeledContent("Cost basis", value: store.portfolioCost.formatted(.currency(code: "USD")))
                    LabeledContent("Unrealised gain/loss", value: store.portfolioGain.formatted(.currency(code: "USD")))
                        .foregroundStyle(store.portfolioGain >= 0 ? .green : .red)
                    if store.holdings.isEmpty {
                        Text("Add holdings below to see allocation and performance.").foregroundStyle(.secondary)
                    } else {
                        Chart(store.holdings) { holding in
                            BarMark(
                                x: .value("Market value", holding.shares * (store.stocks.first(where: { stock in stock.symbol == holding.symbol })?.price ?? holding.averageCost)),
                                y: .value("Symbol", holding.symbol)
                            )
                            .foregroundStyle(by: .value("Symbol", holding.symbol))
                        }
                        .frame(height: 210)
                        let techWeight = store.holdings.filter { holding in
                            store.stocks.first(where: { stock in stock.symbol == holding.symbol })?.sector == "Technology"
                        }.reduce(0.0) { partial, holding in
                            partial + holding.shares * (store.stocks.first(where: { stock in stock.symbol == holding.symbol })?.price ?? holding.averageCost)
                        }
                        if store.portfolioValue > 0 && techWeight / store.portfolioValue > 0.7 {
                            Label("Over 70% concentrated in technology; consider diversification.", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        }
                    }
                }
                Section("Add real holding") {
                    Picker("Symbol", selection: $symbol) { ForEach(store.stocks) { Text($0.symbol).tag($0.symbol) } }
                    TextField("Shares", text: $shares).keyboardType(.decimalPad)
                    TextField("Average buy price ($)", text: $cost).keyboardType(.decimalPad)
                    DatePicker("Purchase date", selection: $date, displayedComponents: .date)
                    Button("Add holding") {
                        let selected = store.stocks.first(where: { $0.symbol == symbol })?.price ?? 0
                        store.addHolding(symbol: symbol, shares: Double(shares) ?? 0, cost: Double(cost) ?? selected, date: date)
                    }.buttonStyle(.borderedProminent)
                }
                Section("Holdings") {
                    ForEach(store.holdings) { holding in
                        let current = store.stocks.first(where: { $0.symbol == holding.symbol })?.price ?? holding.averageCost
                        let gain = (current - holding.averageCost) * holding.shares
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(holding.symbol).font(.headline)
                                Text("\(holding.shares, specifier: "%.3f") shares · cost \(holding.averageCost, format: .currency(code: "USD"))").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text((current * holding.shares).formatted(.currency(code: "USD"))).font(.subheadline.bold())
                                Text(gain.formatted(.currency(code: "USD"))).font(.caption).foregroundStyle(gain >= 0 ? .green : .red)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) { store.deleteHolding(holding) } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
                Section("Portfolio risk") {
                    Text("Risk estimate is currently a simple concentration warning. Correlation-based portfolio risk and rebalancing optimisation are not available in this demo build.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden).background(Color.black)
            .navigationTitle("Portfolio")
        }
    }
}
