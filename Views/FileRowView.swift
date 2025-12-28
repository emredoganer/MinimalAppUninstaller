import SwiftUI

struct FileRowView: View {
    let file: RelatedFile
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if !file.isProtected {
                    onToggle()
                }
            } label: {
                Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(file.isProtected ? .secondary.opacity(0.5) : (file.isSelected ? .accentColor : .secondary))
            }
            .buttonStyle(.plain)
            .disabled(file.isProtected)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(file.path.lastPathComponent)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)

                    if file.isProtected {
                        Text("Protected")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }

                Text(file.displayPath)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(file.formattedSize)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .opacity(file.isProtected ? 0.6 : 1)
    }
}

#Preview {
    VStack(spacing: 0) {
        FileRowView(
            file: RelatedFile(
                path: URL(fileURLWithPath: "/Users/test/Library/Preferences/com.example.app.plist"),
                category: .preferences,
                size: 1024
            ),
            onToggle: {}
        )
        Divider()
        FileRowView(
            file: RelatedFile(
                path: URL(fileURLWithPath: "/Users/test/Library/Containers/com.example.app"),
                category: .containers,
                size: 52428800,
                isProtected: true
            ),
            onToggle: {}
        )
    }
    .frame(width: 450)
}
