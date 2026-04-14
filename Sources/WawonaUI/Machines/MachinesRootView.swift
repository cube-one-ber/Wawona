import SwiftUI
import WawonaModel

struct MachinesRootView: View {
    @ObservedObject var preferences: WawonaPreferences
    @ObservedObject var profileStore: MachineProfileStore
    @ObservedObject var sessions: SessionOrchestrator
    var onPresentNativeCompositor: ((MachineSession) -> Void)?
    @State var search = ""
    @State var showingEditor = false
    @State var editingProfile: MachineProfile?

    init(
        preferences: WawonaPreferences,
        profileStore: MachineProfileStore,
        sessions: SessionOrchestrator,
        onPresentNativeCompositor: ((MachineSession) -> Void)? = nil
    ) {
        self.preferences = preferences
        self.profileStore = profileStore
        self.sessions = sessions
        self.onPresentNativeCompositor = onPresentNativeCompositor
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                MachinesGridView(
                    profiles: filteredProfiles,
                    sessions: sessions,
                    onAdd: { showingEditor = true },
                    onEdit: { editingProfile = $0 },
                    onConnect: connect,
                    onDelete: delete
                )
                .padding()
            }
            .navigationTitle("Machines")
            .searchable(text: $search)
            .sheet(isPresented: $showingEditor) {
                MachineEditorView { profile in
                    profileStore.upsert(profile)
                }
            }
            .sheet(item: $editingProfile) { profile in
                MachineEditorView(profile: profile) { updated in
                    profileStore.upsert(updated)
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
            onPresentNativeCompositor?(session)
        }
        #endif
    }

    private func delete(_ profile: MachineProfile) {
        profileStore.delete(id: profile.id)
    }
}
