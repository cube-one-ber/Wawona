import Foundation
import Observation

public enum MachineType: String, Codable, CaseIterable, Sendable {
    case native
    case sshWaypipe = "ssh_waypipe"
    case sshTerminal = "ssh_terminal"
    case virtualMachine = "virtual_machine"
    case container
}

public enum MachineStatus: String, Codable, CaseIterable, Sendable {
    case disconnected
    case connecting
    case connected
    case degraded
    case error
}

// SKIP @bridgeMembers
public struct MachineProfile: Codable, Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var type: MachineType
    public var sshHost: String
    public var sshUser: String
    public var sshPort: Int
    public var remoteCommand: String
    public var vmSubtype: String
    public var containerSubtype: String
    public var launchers: [ClientLauncher]
    public var favorite: Bool

    public init(
        id: String = UUID().uuidString,
        name: String,
        type: MachineType = .native,
        sshHost: String = "",
        sshUser: String = "",
        sshPort: Int = 22,
        remoteCommand: String = "weston-terminal",
        vmSubtype: String = "",
        containerSubtype: String = "",
        launchers: [ClientLauncher] = [],
        favorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.sshHost = sshHost
        self.sshUser = sshUser
        self.sshPort = sshPort
        self.remoteCommand = remoteCommand
        self.vmSubtype = vmSubtype
        self.containerSubtype = containerSubtype
        self.launchers = launchers
        self.favorite = favorite
    }
}

@Observable
public final class MachineProfileStore {
    public static let profilesKey = "wawona.machineProfiles.v1"
    public static let activeMachineIdKey = "wawona.activeMachineId.v1"

    public private(set) var profiles: [MachineProfile] = []
    public var activeMachineId: String?

    public init() {
        load()
    }

    public func load() {
        let defaults = UserDefaults.standard
        activeMachineId = defaults.string(forKey: Self.activeMachineIdKey)
        guard let data = defaults.data(forKey: Self.profilesKey) else {
            profiles = []
            return
        }
        do {
            profiles = try JSONDecoder().decode([MachineProfile].self, from: data)
        } catch {
            profiles = []
        }
    }

    public func save() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: Self.profilesKey)
        }
        defaults.set(activeMachineId, forKey: Self.activeMachineIdKey)
    }

    public func upsert(_ profile: MachineProfile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
        } else {
            profiles.append(profile)
        }
        save()
    }

    public func delete(id: String) {
        profiles.removeAll { $0.id == id }
        if activeMachineId == id {
            activeMachineId = nil
        }
        save()
    }
}
