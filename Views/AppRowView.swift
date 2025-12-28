import SwiftUI

struct AppRowView: View {
    let app: InstalledApp

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text(app.bundleIdentifier)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    let mockIcon = NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!
    let mockApp = InstalledApp(
        name: "Sample App",
        bundleIdentifier: "com.example.sampleapp",
        path: URL(fileURLWithPath: "/Applications/Sample.app"),
        icon: mockIcon
    )

    return AppRowView(app: mockApp)
        .frame(width: 250)
        .padding()
}
