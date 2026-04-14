import SwiftUI
import WawonaModel

struct MachinesRootView: View {
    @ObservedObject var preferences: WawonaPreferences
    @ObservedObject var profileStore: MachineProfileStore
    @ObservedObject var sessions: SessionOrchestrator
    @State var search = ""
    @State var selectedMachineId: String?
    @State var showingEditor = false

    var body: some View {
        machinesNavigation
    }

    private var machinesNavigation: some View {
        AdaptiveNavigationView {
            #if SKIP
            List(filteredProfiles) { profile in
                Button {
                    selectedMachineId = profile.id
                } label: {
                    Text(profile.name)
                }
            }
            .navigationTitle("Machines")
            #else
            List(selection: $selectedMachineId) {
                ForEach(filteredProfiles) { profile in
                    Text(profile.name).tag(profile.id)
                }
            }
            .navigationTitle("Machines")
            #endif
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
        let session = sessions.connect(machineId: profile.id)
        profileStore.activeMachineId = profile.id
        profileStore.save()
        #if SKIP && os(Android)
        if profile.type == .native {
            NativeCompositorPrefs.apply(for: profile)
            sessions.presentCompositorOverlay(session: session)
        }
        #endif
    }

    private func delete(_ profile: MachineProfile) {
        profileStore.delete(id: profile.id)
    }
}
