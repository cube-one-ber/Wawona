import SwiftUI
import WawonaModel

struct SessionGlanceView: View {
    let profile: MachineProfile
    @Bindable var sessions: SessionOrchestrator

    var body: some View {
        if let session = sessions.sessions.first(where: { $0.machineId == profile.id }) {
            VStack(alignment: .leading) {
                Text("Status: \(session.status.rawValue)")
                Text("Up: \(session.bytesSent)")
                Text("Down: \(session.bytesReceived)")
            }
            .font(.caption)
        } else {
            Text("No active session").font(.caption)
        }
    }
}
