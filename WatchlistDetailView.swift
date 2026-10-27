import SwiftUI

struct WatchlistDetailView: View {
    @EnvironmentObject private var store: TradeSenseStore
    @State private var search = ""
    var body: some View {
        List {
            Section {
                TextField("Search symbol or company", text: $search).textInputAutocapitalization(.characters).autocorrectionDisabled()
            }
            Section("All available demo stocks") {
                ForEach(store.filteredStocks.filter { search.isEmpty || $0.symbol.localizedCaseInsensitiveContains(search) || $0.name.localizedCaseInsensitiveContains(search) }) { stock in
                    HStack {
                        NavigationLink { StockDetailView(stock: stock) } label: { StockRow(stock: stock) }
                        Button {
                            store.watchlist.contains(stock.symbol) ? store.removeFromWatchlist(stock.symbol) : store.addToWatchlist(stock.symbol)
                        } label: {
                            Image(systemName: store.watchlist.contains(stock.symbol) ? "star.fill" : "star")
                                .foregroundStyle(.green)
                        }.buttonStyle(.plain)
                    }
                }
            }
        }.scrollContentBackground(.hidden).background(Color.black).navigationTitle("Stocks")
    }
}
