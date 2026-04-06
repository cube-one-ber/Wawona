import SwiftUI
import WawonaModel

struct InputSettingsView: View {
    @Bindable var preferences: WawonaPreferences
    @State private var keyRepeat = 30.0

    var body: some View {
        Form {
            Section("Input") {
                Slider(value: $keyRepeat, in: 1...60, step: 1) {
                    Text("Key Repeat")
                }
                Text("Repeat: \(Int(keyRepeat))")
            }
        }
        .onDisappear { preferences.save() }
    }
}
