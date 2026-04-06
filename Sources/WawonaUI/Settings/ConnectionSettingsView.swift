import SwiftUI
import WawonaModel

struct ConnectionSettingsView: View {
    @Bindable var preferences: WawonaPreferences

    var body: some View {
        Form {
            Section("Connection") {
                TextField("Wayland Display", text: $preferences.waylandDisplay)
            }
        }
        .onDisappear { preferences.save() }
    }
}
