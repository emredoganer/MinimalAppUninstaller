import Foundation

class OrphanedFileScanner {
    static let shared = OrphanedFileScanner()

    private let fileManager = FileManager.default
    private let homeDirectory = NSHomeDirectory()

    // Minimum file size to consider (1KB)
    private let minimumFileSize: Int64 = 1024

    // Expanded whitelist of protected prefixes
    private let protectedPrefixes = [
        // Apple & macOS
        "com.apple.", "com.mac.",

        // Major Tech Companies
        "com.google.", "com.microsoft.", "com.adobe.",
        "org.mozilla.", "com.brave.", "com.opera.",

        // Development Tools
        "com.jetbrains.", "com.sublimetext.", "com.visualstudio.",
        "com.github.", "io.github.", "com.docker.",
        "com.figma.", "com.sketch.", "com.bohemiancoding.",

        // Communication
        "com.slack.", "com.discord.", "com.zoom.", "us.zoom.",
        "com.skype.", "com.telegram.", "com.tinyspeck.",
        "com.whatsapp.", "com.facebook.",

        // Media & Entertainment
        "com.spotify.", "com.netflix.", "tv.plex.",
        "com.audirvana.", "org.videolan.",

        // Security & Utilities
        "com.1password.", "com.lastpass.", "com.bitwarden.",
        "com.alfredapp.", "com.raycast.", "com.flexibits.",
        "com.agilebits.", "com.objective-see.",

        // Cloud Services
        "com.dropbox.", "com.getdropbox.",

        // Browsers
        "org.chromium.", "com.electron.",

        // Gaming
        "com.valvesoftware.", "com.epicgames.",

        // Productivity
        "com.notion.", "md.obsidian.", "com.todoist.",
        "com.evernote.", "com.readdle."
    ]

    private init() {}

    func scanOrphanedFiles() async -> [OrphanedApp] {
        // Get all installed apps
        let installedApps = await AppScanner.shared.scanApplications()
        let installedBundleIds = Set(installedApps.map { $0.bundleIdentifier })

        var orphanedMap: [String: [RelatedFile]] = [:]

        // Scan all library directories
        let userLibrary = URL(fileURLWithPath: homeDirectory).appendingPathComponent("Library")
        let systemLibrary = URL(fileURLWithPath: "/Library")

        // Scan user library directories
        scanLibraryDirectory(userLibrary.appendingPathComponent("Preferences"),
                             category: .preferences,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(userLibrary.appendingPathComponent("Application Support"),
                             category: .applicationSupport,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(userLibrary.appendingPathComponent("Caches"),
                             category: .caches,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(userLibrary.appendingPathComponent("Logs"),
                             category: .logs,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(userLibrary.appendingPathComponent("Containers"),
                             category: .containers,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(userLibrary.appendingPathComponent("Group Containers"),
                             category: .containers,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(userLibrary.appendingPathComponent("Saved Application State"),
                             category: .savedState,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(userLibrary.appendingPathComponent("WebKit"),
                             category: .webkit,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(userLibrary.appendingPathComponent("HTTPStorages"),
                             category: .cookies,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(userLibrary.appendingPathComponent("Cookies"),
                             category: .cookies,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(userLibrary.appendingPathComponent("LaunchAgents"),
                             category: .launchAgents,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        // Scan system library directories
        scanLibraryDirectory(systemLibrary.appendingPathComponent("Application Support"),
                             category: .applicationSupport,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(systemLibrary.appendingPathComponent("LaunchAgents"),
                             category: .launchAgents,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(systemLibrary.appendingPathComponent("LaunchDaemons"),
                             category: .launchDaemons,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        scanLibraryDirectory(systemLibrary.appendingPathComponent("PrivilegedHelperTools"),
                             category: .launchDaemons,
                             installedBundleIds: installedBundleIds,
                             orphanedMap: &orphanedMap)

        // Convert map to OrphanedApp array
        var orphanedApps: [OrphanedApp] = []
        for (bundleId, files) in orphanedMap {
            let displayName = extractDisplayName(from: bundleId, files: files)
            orphanedApps.append(OrphanedApp(
                bundleIdentifier: bundleId,
                displayName: displayName,
                files: files
            ))
        }

        return orphanedApps.sorted { $0.totalSize > $1.totalSize }
    }

    private func scanLibraryDirectory(_ directory: URL,
                                      category: FileCategory,
                                      installedBundleIds: Set<String>,
                                      orphanedMap: inout [String: [RelatedFile]]) {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentAccessDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for url in contents {
            let fileName = url.lastPathComponent

            // Extract potential bundle identifier or app name
            if let bundleId = extractBundleIdentifier(from: fileName),
               validateBundleIdentifier(bundleId) {
                // Check if this bundle ID is NOT in installed apps
                if !installedBundleIds.contains(bundleId) &&
                   !isProtectedFile(bundleId) {
                    let size = calculateDirectorySize(url)

                    // Skip files smaller than minimum size
                    guard size >= minimumFileSize else { continue }

                    // Get last access date
                    let lastAccessDate = getLastAccessDate(url)

                    let file = RelatedFile(
                        path: url,
                        category: category,
                        size: size,
                        isSelected: false,
                        lastAccessDate: lastAccessDate
                    )

                    if orphanedMap[bundleId] != nil {
                        orphanedMap[bundleId]?.append(file)
                    } else {
                        orphanedMap[bundleId] = [file]
                    }
                }
            }
        }
    }

    private func getLastAccessDate(_ url: URL) -> Date? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.contentAccessDateKey])
            return resourceValues.contentAccessDate
        } catch {
            return nil
        }
    }

    private func extractBundleIdentifier(from fileName: String) -> String? {
        // Remove .plist extension if present
        var name = fileName.replacingOccurrences(of: ".plist", with: "")

        // Remove .savedState extension if present
        name = name.replacingOccurrences(of: ".savedState", with: "")

        // Check if it looks like a bundle identifier (com.company.app format)
        let components = name.split(separator: ".")
        if components.count >= 2 {
            return name
        }

        // For non-bundle-id format, use as-is if it's not too generic
        if name.count > 3 && !name.isEmpty {
            return name
        }

        return nil
    }

    private func validateBundleIdentifier(_ bundleId: String) -> Bool {
        // Use PermissionManager's validation
        return PermissionManager.shared.isValidBundleIdentifier(bundleId)
    }

    private func isProtectedFile(_ bundleId: String) -> Bool {
        // Check against expanded whitelist
        for prefix in protectedPrefixes {
            if bundleId.lowercased().hasPrefix(prefix.lowercased()) {
                return true
            }
        }

        // Also protect common generic names that could be system-related
        let protectedNames = [
            "group.", "sharedcontainer.",
            "CloudDocs", "iCloud", "SyncServices"
        ]

        for name in protectedNames {
            if bundleId.lowercased().contains(name.lowercased()) {
                return true
            }
        }

        return false
    }

    private func extractDisplayName(from bundleId: String, files: [RelatedFile]) -> String {
        // Try to extract a readable name from bundle ID
        let components = bundleId.split(separator: ".")

        if components.count >= 2 {
            // Use the last component as display name
            let lastComponent = String(components.last ?? "")
            return lastComponent.prefix(1).uppercased() + lastComponent.dropFirst()
        }

        return bundleId
    }

    private func calculateDirectorySize(_ url: URL) -> Int64 {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }

        if !isDirectory.boolValue {
            return (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        }

        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) {
            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                      resourceValues.isDirectory == false,
                      let fileSize = resourceValues.fileSize else { continue }
                totalSize += Int64(fileSize)
            }
        }

        return totalSize
    }
}
