import SwiftUI
import WawonaModel

struct MachineDetailView: View {
    let profile: MachineProfile
    @Bindable var sessions: SessionOrchestrator

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(profile.name, subtitle: profile.type.rawValue)
            ForEach(sessions.sessions.filter { $0.machineId == profile.id }) { session in
                GlassCard {
                    VStack(alignment: .leading) {
                        StatusBadge(status: session.status)
                        Text("Sent: \(session.bytesSent) bytes")
                        Text("Received: \(session.bytesReceived) bytes")
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
}
