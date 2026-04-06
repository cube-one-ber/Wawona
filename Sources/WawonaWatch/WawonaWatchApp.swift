import SwiftUI
import WawonaModel

public struct WawonaWatchRootView: View {
    @State private var profileStore = MachineProfileStore()
    @State private var sessions = SessionOrchestrator()

    public init() {}

    public var body: some View {
        NavigationStack {
            MachineStatusView(profileStore: profileStore, sessions: sessions)
        }
    }
}
