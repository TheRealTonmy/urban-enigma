import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: TradeSenseStore
    @State private var query = ""
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("TRADESENSE").font(.caption.weight(.heavy)).tracking(2.5).foregroundStyle(.green)
                            Text("Market intelligence").font(.largeTitle.bold())
                            Text(Date.now.formatted(date: .abbreviated, time: .omitted)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "waveform.path.ecg").font(.title).foregroundStyle(.green)
                    }
                    DisclaimerBanner()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Market snapshot").font(.title3.bold())
                        LazyVGrid(columns: columns, spacing: 10) {
                            marketTile("SPY", "S&P 500", 0.38)
                            marketTile("QQQ", "Nasdaq 100", 0.51)
                            marketTile("DIA", "Dow Jones", 0.21)
                            marketTile("IWM", "Russell 2000", -0.18)
                        }
                        HStack {
                            Text("Market mood")
                            Spacer()
                            Text("NEUTRAL / DEMO").font(.caption.bold()).foregroundStyle(.green)
                        }
                        ProgressView(value: 0.58).tint(.green)
                        Text("Mood is illustrative in this build; live breadth and VIX integration require a data source.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(16).background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 20))
                    HStack {
                        Text("Watchlist").font(.title3.bold())
                        Spacer()
                        NavigationLink("See all") { WatchlistDetailView() }.font(.subheadline.weight(.semibold))
                    }
                    ForEach(store.watchlistStocks.prefix(5)) { stock in
                        NavigationLink { StockDetailView(stock: stock) } label: { StockRow(stock: stock) }
                            .buttonStyle(.plain)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Top picks today").font(.title3.bold())
                        ForEach(store.stocks.sorted { store.prediction(for: $0).score > store.prediction(for: $1).score }.prefix(3)) { stock in
                            let prediction = store.prediction(for: stock)
                            NavigationLink { StockDetailView(stock: stock) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(stock.symbol).font(.headline)
                                        Text(prediction.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                    Spacer()
                                    VerdictBadge(verdict: prediction.verdict)
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding()
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func marketTile(_ symbol: String, _ name: String, _ change: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(symbol).font(.headline)
            Text(name).font(.caption).foregroundStyle(.secondary)
            Text("\(change, specifier: "%+.2f")%").font(.subheadline.bold()).foregroundStyle(change >= 0 ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct VerdictBadge: View {
    let verdict: Verdict
    var color: Color {
        switch verdict { case .buy: return .green; case .hold: return .yellow; case .avoid: return .red }
    }
    var body: some View {
        Text(verdict.rawValue).font(.caption2.bold()).padding(.horizontal, 10).padding(.vertical, 6)
            .foregroundStyle(color).background(color.opacity(0.13), in: Capsule())
    }
}
