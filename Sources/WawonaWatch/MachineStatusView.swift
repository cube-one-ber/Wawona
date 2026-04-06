import SwiftUI
import WawonaModel

struct MachineStatusView: View {
    @Bindable var profileStore: MachineProfileStore
    @Bindable var sessions: SessionOrchestrator

    var body: some View {
        List(profileStore.profiles) { profile in
            NavigationLink(profile.name) {
                QuickConnectView(profile: profile, sessions: sessions)
            }
        }
        .navigationTitle("Machines")
    }
}
