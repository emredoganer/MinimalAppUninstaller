import Foundation

extension URL {
    /// Calculate the total size of a file or directory
    var fileSize: Int64 {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return 0
        }

        if !isDirectory.boolValue {
            return (try? fileManager.attributesOfItem(atPath: path)[.size] as? Int64) ?? 0
        }

        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(
            at: self,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                      values.isDirectory == false,
                      let size = values.fileSize else { continue }
                totalSize += Int64(size)
            }
        }

        return totalSize
    }

    /// Formatted file size string
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}
