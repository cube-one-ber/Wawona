import SwiftUI

struct WWNMachineEditorView: View {
  let title: String
  let initial: WWNMachineProfile?
  let onSave: (WWNMachineProfile) -> Void

  @Environment(\.dismiss) private var dismiss

  @State private var name: String
  @State private var type: String
  @State private var sshHost: String
  @State private var sshUser: String
  @State private var sshPassword: String
  @State private var sshKeyPath: String
  @State private var remoteCommand: String
  @State private var vmSubtype: String
  @State private var containerSubtype: String

  init(title: String, initial: WWNMachineProfile?, onSave: @escaping (WWNMachineProfile) -> Void) {
    self.title = title
    self.initial = initial
    self.onSave = onSave
    _name = State(initialValue: initial?.name ?? "")
    _type = State(initialValue: initial?.type ?? kWWNMachineTypeSSHWaypipe)
    _sshHost = State(initialValue: initial?.sshHost ?? "")
    _sshUser = State(initialValue: initial?.sshUser ?? "")
    _sshPassword = State(initialValue: initial?.sshPassword ?? "")
    _sshKeyPath = State(initialValue: initial?.sshKeyPath ?? "")
    _remoteCommand = State(initialValue: initial?.remoteCommand ?? "")
    _vmSubtype = State(initialValue: initial?.vmSubtype ?? "qemu")
    _containerSubtype = State(initialValue: initial?.containerSubtype ?? "docker")
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Connection Profile") {
          TextField("Display name", text: $name)
        }

        Section("Machine Mode") {
          Picker("Type", selection: $type) {
            Text("Native").tag(kWWNMachineTypeNative)
            Text("SSH + Waypipe").tag(kWWNMachineTypeSSHWaypipe)
            Text("SSH Terminal").tag(kWWNMachineTypeSSHTerminal)
            Text("Virtual Machine").tag(kWWNMachineTypeVirtualMachine)
            Text("Container").tag(kWWNMachineTypeContainer)
          }
          .pickerStyle(.segmented)
        }

        if type == kWWNMachineTypeSSHWaypipe || type == kWWNMachineTypeSSHTerminal {
          Section("Remote Connectivity") {
            TextField("Host", text: $sshHost)
            TextField("User", text: $sshUser)
            SecureField("Password", text: $sshPassword)
            TextField("SSH key path", text: $sshKeyPath)
            TextField("Remote startup command", text: $remoteCommand)
          }
        }

        if type == kWWNMachineTypeVirtualMachine {
          Section("VM Configuration") {
            TextField("VM subtype (qemu, utm, ...)", text: $vmSubtype)
            Text("VM launch support is a stub until runtime integration lands.")
              .foregroundStyle(.secondary)
          }
        }

        if type == kWWNMachineTypeContainer {
          Section("Container Configuration") {
            TextField("Container subtype (docker, podman, ...)", text: $containerSubtype)
            TextField("Container startup command", text: $remoteCommand)
            Text("Container launch support is a stub until runtime integration lands.")
              .foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle(title)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save", action: save)
        }
      }
    }
    #if os(macOS)
    .frame(minWidth: 420, idealWidth: 560, maxWidth: 720, minHeight: 440, idealHeight: 640)
    #endif
  }

  private func save() {
    let profile = initial ?? WWNMachineProfile.default()
    profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unnamed Machine" : name
    profile.type = type
    profile.sshHost = sshHost.trimmingCharacters(in: .whitespacesAndNewlines)
    profile.sshUser = sshUser.trimmingCharacters(in: .whitespacesAndNewlines)
    profile.sshPassword = sshPassword
    profile.sshKeyPath = sshKeyPath.trimmingCharacters(in: .whitespacesAndNewlines)
    profile.remoteCommand = remoteCommand.trimmingCharacters(in: .whitespacesAndNewlines)
    profile.vmSubtype = vmSubtype.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "qemu" : vmSubtype
    profile.containerSubtype =
      containerSubtype.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "docker" : containerSubtype
    onSave(profile)
    dismiss()
  }
}
