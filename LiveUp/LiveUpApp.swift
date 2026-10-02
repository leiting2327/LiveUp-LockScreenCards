import SwiftUI

@main
struct LiveUpApp: App {
    @StateObject private var store = CardStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
