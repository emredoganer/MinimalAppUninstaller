import Foundation

struct RelatedFile: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let category: FileCategory
    let size: Int64
    var isSelected: Bool = true
    var isProtected: Bool = false

    var displayPath: String {
        path.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: RelatedFile, rhs: RelatedFile) -> Bool {
        lhs.path == rhs.path
    }
}
