import AppKit
import Foundation

class PermissionManager {
    static let shared = PermissionManager()

    private var cachedSIPStatus: Bool?
    private var sipCheckTime: Date?

    private init() {}

    /// Check if the app has Full Disk Access using multiple test paths
    var hasFullDiskAccess: Bool {
        // SECURITY: Test multiple paths to ensure accurate FDA detection
        let testPaths = [
            NSHomeDirectory() + "/Library/Containers",
            NSHomeDirectory() + "/Library/Mail",
            NSHomeDirectory() + "/Library/Messages",
            NSHomeDirectory() + "/Library/Safari"
        ]

        // Must be able to read at least the Containers directory
        let primaryPath = testPaths[0]
        guard FileManager.default.isReadableFile(atPath: primaryPath) else {
            return false
        }

        // Check additional paths for more confidence
        var accessibleCount = 0
        for path in testPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                accessibleCount += 1
            }
        }

        // Require at least 2 paths to be accessible
        return accessibleCount >= 2
    }

    /// Opens System Preferences to the Privacy & Security > Full Disk Access section
    func openFullDiskAccessSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    /// Check if a path requires admin privileges
    func requiresAdmin(path: URL) -> Bool {
        let resolvedPath = path.resolvingSymlinksInPath().path
        
        let systemPaths = [
            "/Library/",
            "/System/",
            "/usr/",
            "/bin/",
            "/sbin/",
            "/private/"
        ]

        return systemPaths.contains { resolvedPath.hasPrefix($0) }
    }

    /// Check if we can write to a path
    func canWrite(to path: URL) -> Bool {
        FileManager.default.isWritableFile(atPath: path.path)
    }

    /// Check if a path is protected by SIP or other system protections (Enhanced)
    func isSystemProtected(path: URL) -> Bool {
        let resolvedPath = path.resolvingSymlinksInPath().path
        
        let protectedPaths = [
            // Core system directories
            "/System/",
            "/usr/bin/",
            "/usr/lib/",
            "/usr/sbin/",
            "/usr/share/",
            "/bin/",
            "/sbin/",
            
            // Private system directories
            "/private/var/db/",
            "/private/var/folders/",
            "/private/etc/",
            
            // Apple-specific
            "/Library/Apple/",
            "/Library/SystemConfiguration/",
            "/Library/DirectoryServices/",
            "/Library/Filesystems/",
            "/Library/Frameworks/",
            "/Library/Keychains/",
            "/Library/Security/",
            
            // System utilities that should never be removed
            "/Applications/Utilities/Terminal.app",
            "/Applications/Utilities/Activity Monitor.app",
            "/Applications/Utilities/Disk Utility.app",
            "/Applications/Utilities/Console.app",
            "/Applications/Utilities/Keychain Access.app",
            "/Applications/Utilities/System Information.app",
            
            // Core Apple apps
            "/Applications/Safari.app",
            "/Applications/App Store.app",
            "/Applications/System Preferences.app",
            "/Applications/System Settings.app",
            "/Applications/Finder.app"
        ]

        // Check against protected paths
        if protectedPaths.contains(where: { resolvedPath.hasPrefix($0) || resolvedPath == $0.dropLast() }) {
            return true
        }
        
        // Check if path is SIP protected using csrutil (cached check)
        if isSIPProtectedPath(resolvedPath) {
            return true
        }
        
        return false
    }
    
    /// Check for specific SIP-protected paths with runtime verification
    private func isSIPProtectedPath(_ path: String) -> Bool {
        let sipProtectedRoots = [
            "/System",
            "/usr",
            "/bin",
            "/sbin",
            "/var"
        ]

        for root in sipProtectedRoots {
            if path == root || path.hasPrefix(root + "/") {
                // Allow specific subdirectories that are not SIP protected
                let allowedSubpaths = [
                    "/usr/local/",
                    "/var/tmp/",
                    "/var/folders/"
                ]

                if allowedSubpaths.contains(where: { path.hasPrefix($0) }) {
                    continue
                }

                return true
            }
        }

        return false
    }

    /// Check if SIP is enabled on this system (cached for performance)
    func isSIPEnabled() -> Bool {
        // SECURITY: Cache SIP status for 5 minutes to avoid repeated process spawns
        if let cached = cachedSIPStatus,
           let checkTime = sipCheckTime,
           Date().timeIntervalSince(checkTime) < 300 {
            return cached
        }

        let result = checkSIPStatusRuntime()
        cachedSIPStatus = result
        sipCheckTime = Date()
        return result
    }

    /// Runtime check using csrutil status
    private func checkSIPStatusRuntime() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/csrutil")
        task.arguments = ["status"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // "System Integrity Protection status: enabled."
                // "System Integrity Protection status: disabled."
                return output.lowercased().contains("enabled")
            }
        } catch {
            // If we can't check, assume SIP is enabled for safety
            return true
        }

        // Default to enabled for safety
        return true
    }

    /// Check if a specific path is protected by SIP at runtime
    func isPathSIPProtected(_ path: String) -> Bool {
        // First check against known SIP roots
        if isSIPProtectedPath(path) {
            // Only report as protected if SIP is actually enabled
            return isSIPEnabled()
        }
        return false
    }
    
    /// Validate that a bundle identifier looks legitimate
    func isValidBundleIdentifier(_ bundleId: String) -> Bool {
        let pattern = "^[a-zA-Z][a-zA-Z0-9-]*(\\.[a-zA-Z0-9-]+)+$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        
        let range = NSRange(bundleId.startIndex..., in: bundleId)
        return regex.firstMatch(in: bundleId, range: range) != nil
    }
}
