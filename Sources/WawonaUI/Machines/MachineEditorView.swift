import SwiftUI
import WawonaModel

struct MachineEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: MachineType = .native
    @State private var sshHost = ""
    @State private var sshUser = ""
    @State private var sshPort = 22
    @State private var launchers: [ClientLauncher] = []

    let onSave: (MachineProfile) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(MachineType.allCases, id: \.self) { machineType in
                            Text(machineType.rawValue).tag(machineType)
                        }
                    }
                }

                Section("SSH") {
                    TextField("Host", text: $sshHost)
                    TextField("User", text: $sshUser)
                    Stepper("Port \(sshPort)", value: $sshPort, in: 1...65535)
                }

                Section("Clients") {
                    ForEach(launchers) { launcher in
                        Text(launcher.displayName)
                    }
                    Button("Add Weston Terminal") {
                        launchers.append(
                            ClientLauncher(
                                name: "weston-terminal",
                                executablePath: "weston-terminal",
                                displayName: "Weston Terminal"
                            )
                        )
                    }
                }
            }
            .navigationTitle("Machine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            MachineProfile(
                                name: name.isEmpty ? "Unnamed Machine" : name,
                                type: type,
                                sshHost: sshHost,
                                sshUser: sshUser,
                                sshPort: sshPort,
                                launchers: launchers
                            )
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
