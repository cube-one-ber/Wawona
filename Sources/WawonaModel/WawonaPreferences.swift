import Foundation
import Observation

@Observable
public final class WawonaPreferences {
    public static let shared = WawonaPreferences()

    public var renderer: String = "metal"
    public var forceSSD: Bool = false
    public var autoScale: Bool = true
    public var waylandDisplay: String = "wayland-0"
    public var sshHost: String = ""
    public var sshUser: String = ""
    public var sshPort: Int = 22
    public var logLevel: String = "info"
    public var hasCompletedWelcome: Bool = false
    public var globalClientLaunchers: [ClientLauncher] = ClientLauncher.presets

    private let defaults = UserDefaults.standard
    private let keyPrefix = "wawona.pref."

    public init() {
        load()
    }

    public func load() {
        renderer = defaults.string(forKey: keyPrefix + "renderer") ?? "metal"
        forceSSD = defaults.bool(forKey: keyPrefix + "forceSSD")
        autoScale = defaults.object(forKey: keyPrefix + "autoScale") as? Bool ?? true
        waylandDisplay = defaults.string(forKey: keyPrefix + "waylandDisplay") ?? "wayland-0"
        sshHost = defaults.string(forKey: keyPrefix + "sshHost") ?? ""
        sshUser = defaults.string(forKey: keyPrefix + "sshUser") ?? ""
        sshPort = defaults.object(forKey: keyPrefix + "sshPort") as? Int ?? 22
        logLevel = defaults.string(forKey: keyPrefix + "logLevel") ?? "info"
        hasCompletedWelcome = defaults.bool(forKey: keyPrefix + "hasCompletedWelcome")

        if let launchersData = defaults.data(forKey: keyPrefix + "globalClientLaunchers"),
           let launchers = try? JSONDecoder().decode([ClientLauncher].self, from: launchersData) {
            globalClientLaunchers = launchers
        }
    }

    public func save() {
        defaults.set(renderer, forKey: keyPrefix + "renderer")
        defaults.set(forceSSD, forKey: keyPrefix + "forceSSD")
        defaults.set(autoScale, forKey: keyPrefix + "autoScale")
        defaults.set(waylandDisplay, forKey: keyPrefix + "waylandDisplay")
        defaults.set(sshHost, forKey: keyPrefix + "sshHost")
        defaults.set(sshUser, forKey: keyPrefix + "sshUser")
        defaults.set(sshPort, forKey: keyPrefix + "sshPort")
        defaults.set(logLevel, forKey: keyPrefix + "logLevel")
        defaults.set(hasCompletedWelcome, forKey: keyPrefix + "hasCompletedWelcome")
        if let data = try? JSONEncoder().encode(globalClientLaunchers) {
            defaults.set(data, forKey: keyPrefix + "globalClientLaunchers")
        }
    }
}
