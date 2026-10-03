import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CardsTabView()
                .tabItem { Label("卡片", systemImage: "lock.square") }
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
    }
}
