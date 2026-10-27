import SwiftUI
import Charts

struct DisclaimerBanner: View {
    var body: some View {
        Label("Not financial advice. Predictions are estimates and can be wrong.", systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(.orange)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StockRow: View {
    let stock: Stock
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.13))
                .frame(width: 42, height: 42)
                .overlay(Text(String(stock.symbol.prefix(1))).font(.headline.bold()).foregroundStyle(.green))
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol).font(.headline)
                Text(stock.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(stock.price, format: .currency(code: stock.currency)).font(.subheadline.weight(.semibold))
                Text("\(stock.changePercent, specifier: "%+.2f")%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(stock.changePercent >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PriceLineChart: View {
    let stock: Stock
    var body: some View {
        Chart(Array(stock.history.suffix(90))) { candle in
            LineMark(x: .value("Date", candle.date), y: .value("Close", candle.close))
                .foregroundStyle(Color.green.gradient)
                .interpolationMethod(.catmullRom)
            AreaMark(x: .value("Date", candle.date), yStart: .value("Base", stock.history.suffix(90).map(\.close).min() ?? candle.close), yEnd: .value("Close", candle.close))
                .foregroundStyle(LinearGradient(colors: [Color.green.opacity(0.24), Color.green.opacity(0.01)], startPoint: .top, endPoint: .bottom))
        }
        .chartXAxis(.hidden)
        .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) }
        .frame(height: 190)
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let caption: String
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            Text(value).font(.title3.bold()).minimumScaleFactor(0.7).lineLimit(1)
            Text(caption).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 15))
    }
}
