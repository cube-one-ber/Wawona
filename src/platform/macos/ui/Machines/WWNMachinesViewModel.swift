import Foundation
import Combine

@objc enum WWNMachineTransientStatus: Int, CaseIterable {
  case disconnected
  case connecting
  case connected
  case degraded
  case error

  var title: String {
    switch self {
    case .disconnected: return "Disconnected"
    case .connecting: return "Connecting"
    case .connected: return "Connected"
    case .degraded: return "Degraded"
    case .error: return "Error"
    }
  }
}

@MainActor
final class WWNMachinesViewModel: ObservableObject {
  @Published private(set) var profiles: [WWNMachineProfile] = []
  @Published private(set) var statusByMachineId: [String: WWNMachineTransientStatus] = [:]
  @Published var selectedFilter: WWNMachineFilter = .all

  init() {
    reload()
  }

  var activeMachineId: String? {
    WWNMachineProfileStore.activeMachineId()
  }

  var filteredProfiles: [WWNMachineProfile] {
    switch selectedFilter {
    case .all:
      return profiles
    case .local:
      return profiles.filter { profile in
        profile.type == kWWNMachineTypeNative ||
          profile.type == kWWNMachineTypeVirtualMachine ||
          profile.type == kWWNMachineTypeContainer
      }
    case .remote:
      return profiles.filter { profile in
        profile.type == kWWNMachineTypeSSHWaypipe ||
          profile.type == kWWNMachineTypeSSHTerminal
      }
    }
  }

  var connectedCount: Int {
    profiles.reduce(0) { partial, profile in
      partial + (status(for: profile.machineId) == .connected ? 1 : 0)
    }
  }

  var launchableCount: Int {
    profiles.reduce(0) { partial, profile in
      partial + (launchSupported(for: profile) ? 1 : 0)
    }
  }

  func reload() {
    profiles = WWNMachineProfileStore.loadProfiles()
    for profile in profiles {
      if statusByMachineId[profile.machineId] == nil {
        statusByMachineId[profile.machineId] = .disconnected
      }
    }
  }

  func upsert(_ profile: WWNMachineProfile) {
    profiles = WWNMachineProfileStore.upsertProfile(profile)
    if statusByMachineId[profile.machineId] == nil {
      statusByMachineId[profile.machineId] = .disconnected
    }
  }

  func delete(_ profile: WWNMachineProfile) {
    profiles = WWNMachineProfileStore.deleteProfile(byId: profile.machineId)
    statusByMachineId.removeValue(forKey: profile.machineId)
  }

  func status(for machineId: String) -> WWNMachineTransientStatus {
    statusByMachineId[machineId] ?? .disconnected
  }

  func connect(_ profile: WWNMachineProfile, onConnected: (() -> Void)? = nil) {
    statusByMachineId[profile.machineId] = .connecting
    WWNMachineProfileStore.applyMachine(toRuntimePrefs: profile)
    WWNMachineProfileStore.setActiveMachineId(profile.machineId)

    if profile.type == kWWNMachineTypeNative {
      statusByMachineId[profile.machineId] = .connected
      onConnected?()
      return
    }

    if profile.type == kWWNMachineTypeVirtualMachine ||
      profile.type == kWWNMachineTypeContainer {
      statusByMachineId[profile.machineId] = .degraded
      return
    }

    WWNWaypipeRunner.shared().launchWaypipe(WWNPreferencesManager.shared())
    statusByMachineId[profile.machineId] = .connected
    onConnected?()
  }

  func machineTypeLabel(for profile: WWNMachineProfile) -> String {
    switch profile.type {
    case kWWNMachineTypeNative:
      return "Native"
    case kWWNMachineTypeSSHWaypipe:
      return "SSH + Waypipe"
    case kWWNMachineTypeSSHTerminal:
      return "SSH Terminal"
    case kWWNMachineTypeVirtualMachine:
      return "Virtual Machine"
    case kWWNMachineTypeContainer:
      return "Container"
    default:
      return profile.type
    }
  }

  func machineScopeLabel(for profile: WWNMachineProfile) -> String {
    switch profile.type {
    case kWWNMachineTypeNative, kWWNMachineTypeVirtualMachine, kWWNMachineTypeContainer:
      return "Local"
    default:
      return "Remote"
    }
  }

  func machineSubtitle(for profile: WWNMachineProfile) -> String {
    switch profile.type {
    case kWWNMachineTypeNative:
      return "Runs directly on this host"
    case kWWNMachineTypeVirtualMachine:
      let subtype = profile.vmSubtype.isEmpty ? "qemu" : profile.vmSubtype
      return "VM profile (\(subtype.uppercased()))"
    case kWWNMachineTypeContainer:
      let subtype = profile.containerSubtype.isEmpty ? "docker" : profile.containerSubtype
      return "Container profile (\(subtype.uppercased()))"
    default:
      if profile.sshHost.isEmpty {
        return "SSH endpoint not configured"
      }
      let user = profile.sshUser.isEmpty ? "user" : profile.sshUser
      return "\(user)@\(profile.sshHost)"
    }
  }

  func machineConfigurationSummary(for profile: WWNMachineProfile) -> String {
    switch profile.type {
    case kWWNMachineTypeSSHWaypipe:
      let command = profile.remoteCommand.isEmpty ? "weston-terminal" : profile.remoteCommand
      return "Waypipe command: \(command)"
    case kWWNMachineTypeSSHTerminal:
      let command = profile.remoteCommand.isEmpty ? "terminal default" : profile.remoteCommand
      return "SSH terminal command: \(command)"
    case kWWNMachineTypeVirtualMachine:
      return "Subtype: \(profile.vmSubtype.isEmpty ? "qemu" : profile.vmSubtype)"
    case kWWNMachineTypeContainer:
      return "Subtype: \(profile.containerSubtype.isEmpty ? "docker" : profile.containerSubtype)"
    default:
      return "No remote transport required"
    }
  }

  func launchSupported(for profile: WWNMachineProfile) -> Bool {
    profile.type == kWWNMachineTypeNative ||
      profile.type == kWWNMachineTypeSSHWaypipe ||
      profile.type == kWWNMachineTypeSSHTerminal
  }
}

enum WWNMachineFilter: String, CaseIterable, Identifiable {
  case all = "All Machines"
  case local = "Local"
  case remote = "Remote"

  var id: String { rawValue }
}
