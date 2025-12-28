import AppKit
import Foundation

class PermissionManager {
    static let shared = PermissionManager()

    private init() {}

    /// Check if the app has Full Disk Access
    var hasFullDiskAccess: Bool {
        // Try to read a protected directory to check FDA
        let testPath = NSHomeDirectory() + "/Library/Containers"
        return FileManager.default.isReadableFile(atPath: testPath)
    }

    /// Opens System Preferences to the Privacy & Security > Full Disk Access section
    func openFullDiskAccessSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    /// Check if a path requires admin privileges
    func requiresAdmin(path: URL) -> Bool {
        let systemPaths = [
            "/Library/",
            "/System/",
            "/usr/",
            "/bin/",
            "/sbin/"
        ]

        return systemPaths.contains { path.path.hasPrefix($0) }
    }

    /// Check if we can write to a path
    func canWrite(to path: URL) -> Bool {
        FileManager.default.isWritableFile(atPath: path.path)
    }

    /// Check if a path is protected by SIP or other system protections
    func isSystemProtected(path: URL) -> Bool {
        let protectedPaths = [
            "/System/",
            "/usr/bin/",
            "/usr/lib/",
            "/usr/sbin/"
        ]

        return protectedPaths.contains { path.path.hasPrefix($0) }
    }
}
