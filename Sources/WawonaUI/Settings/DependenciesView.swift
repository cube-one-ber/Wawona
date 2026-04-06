import SwiftUI

struct DependenciesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wayland")
            Text("waypipe")
            Text("xkbcommon")
            Text("Mesa")
            Text("libssh2")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
