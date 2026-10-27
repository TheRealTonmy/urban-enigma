import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: TradeSenseStore
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Markets", systemImage: "chart.xyaxis.line") }
            AnalysisView().tabItem { Label("Analysis", systemImage: "waveform.path.ecg") }
            SimulationView().tabItem { Label("Simulate", systemImage: "flask") }
            PortfolioView().tabItem { Label("Portfolio", systemImage: "chart.pie") }
            ToolsView().tabItem { Label("More", systemImage: "square.grid.2x2") }
        }
        .overlay {
            if store.faceIDEnabled && !store.isUnlocked {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "faceid").font(.system(size: 54)).foregroundStyle(.green)
                        Text("TradeSense is locked").font(.title2.bold())
                        Button("Unlock") { Task { await store.unlockWithBiometrics() } }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .alert("TradeSense", isPresented: Binding(get: { store.statusMessage != nil }, set: { if !$0 { store.statusMessage = nil } })) {
            Button("OK", role: .cancel) { store.statusMessage = nil }
        } message: { Text(store.statusMessage ?? "") }
    }
}
