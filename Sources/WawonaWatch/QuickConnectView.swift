import SwiftUI
import WawonaModel

struct QuickConnectView: View {
    let profile: MachineProfile
    @Bindable var sessions: SessionOrchestrator

    var body: some View {
        VStack(spacing: 10) {
            Text(profile.name).font(.headline)
            Button("Connect") {
                _ = sessions.connect(machineId: profile.id)
            }
            Button("Disconnect") {
                if let session = sessions.sessions.first(where: { $0.machineId == profile.id }) {
                    sessions.disconnect(sessionId: session.id)
                }
            }
            SessionGlanceView(profile: profile, sessions: sessions)
        }
    }
}
