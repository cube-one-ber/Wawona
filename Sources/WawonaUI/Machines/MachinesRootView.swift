import SwiftUI
import WawonaModel

struct MachinesRootView: View {
    @Bindable var preferences: WawonaPreferences
    @Bindable var profileStore: MachineProfileStore
    @Bindable var sessions: SessionOrchestrator
    @State private var search = ""
    @State private var selectedMachineId: String?
    @State private var showingEditor = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedMachineId) {
                ForEach(filteredProfiles) { profile in
                    Text(profile.name).tag(profile.id)
                }
            }
            .navigationTitle("Machines")
        } detail: {
            ScrollView {
                MachinesGridView(
                    profiles: filteredProfiles,
                    sessions: sessions,
                    onAdd: { showingEditor = true },
                    onConnect: connect,
                    onDelete: delete
                )
                .padding()
            }
            .searchable(text: $search)
            .sheet(isPresented: $showingEditor) {
                MachineEditorView { profile in
                    profileStore.upsert(profile)
                }
            }
        }
    }

    private var filteredProfiles: [MachineProfile] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return profileStore.profiles }
        return profileStore.profiles.filter {
            $0.name.lowercased().contains(q) || $0.sshHost.lowercased().contains(q)
        }
    }

    private func connect(_ profile: MachineProfile) {
        _ = sessions.connect(machineId: profile.id)
        profileStore.activeMachineId = profile.id
        profileStore.save()
    }

    private func delete(_ profile: MachineProfile) {
        profileStore.delete(id: profile.id)
    }
}
