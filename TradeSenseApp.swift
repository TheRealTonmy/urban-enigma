import SwiftUI

@main
struct TradeSenseApp: App {
    @StateObject private var store = TradeSenseStore()
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(.green)
        }
    }
}
