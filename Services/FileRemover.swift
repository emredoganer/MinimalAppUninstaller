import AppKit
import Foundation

enum RemovalError: LocalizedError {
    case permissionDenied(URL)
    case fileNotFound(URL)
    case systemProtected(URL)
    case unknown(URL, Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let url):
            return "Permission denied: \(url.lastPathComponent)"
        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"
        case .systemProtected(let url):
            return "System protected: \(url.lastPathComponent)"
        case .unknown(let url, let error):
            return "Error removing \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }
}

struct RemovalResult {
    let file: RelatedFile
    let success: Bool
    let error: RemovalError?
}

class FileRemover {
    static let shared = FileRemover()

    private let fileManager = FileManager.default
    private let permissionManager = PermissionManager.shared

    private init() {}

    /// Remove a list of files with progress callback
    func removeFiles(_ files: [RelatedFile],
                     progress: @escaping (Int, Int) -> Void,
                     completion: @escaping ([RemovalResult]) -> Void) {

        Task {
            var results: [RemovalResult] = []
            let total = files.count

            for (index, file) in files.enumerated() {
                let result = await removeFile(file)
                results.append(result)

                await MainActor.run {
                    progress(index + 1, total)
                }
            }

            await MainActor.run {
                completion(results)
            }
        }
    }

    /// Remove a single file
    func removeFile(_ file: RelatedFile) async -> RemovalResult {
        let url = file.path

        // Check if file exists
        guard fileManager.fileExists(atPath: url.path) else {
            return RemovalResult(file: file, success: false, error: .fileNotFound(url))
        }

        // Check if system protected
        if permissionManager.isSystemProtected(path: url) {
            return RemovalResult(file: file, success: false, error: .systemProtected(url))
        }

        // Check if requires admin
        if permissionManager.requiresAdmin(path: url) {
            return await removeWithPrivileges(file)
        }

        // Try normal removal
        do {
            try fileManager.removeItem(at: url)
            return RemovalResult(file: file, success: true, error: nil)
        } catch let error as NSError {
            if error.code == NSFileWriteNoPermissionError {
                return RemovalResult(file: file, success: false, error: .permissionDenied(url))
            }
            return RemovalResult(file: file, success: false, error: .unknown(url, error))
        }
    }

    /// Remove file using privileged helper or AppleScript
    private func removeWithPrivileges(_ file: RelatedFile) async -> RemovalResult {
        let url = file.path

        let script = """
        do shell script "rm -rf '\(url.path)'" with administrator privileges
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)

            if error == nil && !fileManager.fileExists(atPath: url.path) {
                return RemovalResult(file: file, success: true, error: nil)
            }
        }

        return RemovalResult(file: file, success: false, error: .permissionDenied(url))
    }

    /// Move files to Trash instead of permanent deletion
    func moveToTrash(_ files: [RelatedFile],
                     progress: @escaping (Int, Int) -> Void,
                     completion: @escaping ([RemovalResult]) -> Void) {

        Task {
            var results: [RemovalResult] = []
            let total = files.count

            for (index, file) in files.enumerated() {
                let result = await moveFileToTrash(file)
                results.append(result)

                await MainActor.run {
                    progress(index + 1, total)
                }
            }

            await MainActor.run {
                completion(results)
            }
        }
    }

    private func moveFileToTrash(_ file: RelatedFile) async -> RemovalResult {
        let url = file.path

        guard fileManager.fileExists(atPath: url.path) else {
            return RemovalResult(file: file, success: false, error: .fileNotFound(url))
        }

        // First, try normal trashItem
        do {
            try fileManager.trashItem(at: url, resultingItemURL: nil)
            return RemovalResult(file: file, success: true, error: nil)
        } catch {
            // Normal trash failed, try with admin privileges
            return removeWithAdminPrivileges(file)
        }
    }

    /// Remove file using admin privileges (for root-owned App Store apps)
    private func removeWithAdminPrivileges(_ file: RelatedFile) -> RemovalResult {
        let url = file.path

        // Escape single quotes for shell: replace ' with '\''
        let escapedPath = url.path.replacingOccurrences(of: "'", with: "'\\''")

        // Use rm -rf with admin privileges for root-owned files
        let script = """
        do shell script "rm -rf '\(escapedPath)'" with administrator privileges
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)

            // Check if file was removed
            if error == nil && !fileManager.fileExists(atPath: url.path) {
                return RemovalResult(file: file, success: true, error: nil)
            }
        }

        return RemovalResult(file: file, success: false, error: .permissionDenied(url))
    }
}
