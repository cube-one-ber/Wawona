import SwiftUI
import WawonaModel

struct SSHWaypipeSettingsView: View {
    @Bindable var preferences: WawonaPreferences

    var body: some View {
        Form {
            Section("SSH") {
                TextField("Host", text: $preferences.sshHost)
                TextField("User", text: $preferences.sshUser)
                Stepper("Port \(preferences.sshPort)", value: $preferences.sshPort, in: 1...65535)
            }
        }
        .onDisappear { preferences.save() }
    }
}
