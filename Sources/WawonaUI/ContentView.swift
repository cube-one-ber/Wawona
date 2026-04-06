import SwiftUI
import WawonaModel

struct ContentView: View {
    @Bindable var preferences: WawonaPreferences
    @Bindable var profileStore: MachineProfileStore
    @Bindable var sessions: SessionOrchestrator

    var body: some View {
        TabView {
            MachinesRootView(
                preferences: preferences,
                profileStore: profileStore,
                sessions: sessions
            )
            .tabItem { Label("Machines", systemImage: "square.grid.2x2") }

            SettingsRootView(preferences: preferences)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
