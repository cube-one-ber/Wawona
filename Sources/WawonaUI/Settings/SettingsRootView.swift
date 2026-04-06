import SwiftUI
import WawonaModel

struct SettingsRootView: View {
    @Bindable var preferences: WawonaPreferences
    @State private var selection: String? = "display"

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Text("Display").tag("display")
                Text("Input").tag("input")
                Text("Graphics").tag("graphics")
                Text("Connection").tag("connection")
                Text("SSH / Waypipe").tag("ssh")
                Text("Clients").tag("clients")
                Text("Advanced").tag("advanced")
                Text("About").tag("about")
            }
            .navigationTitle("Settings")
        } detail: {
            switch selection {
            case "display": DisplaySettingsView(preferences: preferences)
            case "input": InputSettingsView(preferences: preferences)
            case "graphics": GraphicsSettingsView(preferences: preferences)
            case "connection": ConnectionSettingsView(preferences: preferences)
            case "ssh": SSHWaypipeSettingsView(preferences: preferences)
            case "clients": ClientsSettingsView(preferences: preferences)
            case "advanced": AdvancedSettingsView(preferences: preferences)
            case "about": AboutView()
            default: DisplaySettingsView(preferences: preferences)
            }
        }
    }
}
