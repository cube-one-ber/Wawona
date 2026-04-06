import Foundation
import SwiftUI
import WawonaModel

// SKIP @bridge
public struct WawonaRootView: View {
    @State private var preferences = WawonaPreferences.shared
    @State private var profileStore = MachineProfileStore()
    @State private var sessions = SessionOrchestrator()

    public init() {}

    public var body: some View {
        Group {
            if preferences.hasCompletedWelcome || !profileStore.profiles.isEmpty {
                ContentView(
                    preferences: preferences,
                    profileStore: profileStore,
                    sessions: sessions
                )
            } else {
                WelcomeView(preferences: preferences)
            }
        }
    }
}

// SKIP @bridge
public final class WawonaAppDelegate: Sendable {
    // SKIP @bridge
    public static let shared = WawonaAppDelegate()

    public init() {}

    // SKIP @bridge
    public func onInit() {}
    // SKIP @bridge
    public func onLaunch() {}
    // SKIP @bridge
    public func onResume() {}
    // SKIP @bridge
    public func onPause() {}
    // SKIP @bridge
    public func onStop() {}
    // SKIP @bridge
    public func onDestroy() {}
    // SKIP @bridge
    public func onLowMemory() {}
}
