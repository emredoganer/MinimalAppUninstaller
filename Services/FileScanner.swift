import Foundation

class FileScanner {
    static let shared = FileScanner()

    private let fileManager = FileManager.default
    private let homeDirectory = NSHomeDirectory()

    private init() {}

    func scanRelatedFiles(for app: InstalledApp) async -> [RelatedFile] {
        var files: [RelatedFile] = []
        let appName = app.displayName
        let bundleId = app.bundleIdentifier

        // User Library paths
        let userLibrary = URL(fileURLWithPath: homeDirectory).appendingPathComponent("Library")

        // Application Support - don't use developerName to avoid matching shared folders like "Google", "Adobe"
        files += scanDirectory(userLibrary.appendingPathComponent("Application Support"),
                              searchTerms: [appName, bundleId],
                              category: .applicationSupport)

        // Preferences
        files += scanForFiles(in: userLibrary.appendingPathComponent("Preferences"),
                             pattern: bundleId,
                             category: .preferences)

        // Caches
        files += scanDirectory(userLibrary.appendingPathComponent("Caches"),
                              searchTerms: [appName, bundleId],
                              category: .caches)

        // Logs
        files += scanDirectory(userLibrary.appendingPathComponent("Logs"),
                              searchTerms: [appName, bundleId],
                              category: .logs)

        // Containers
        let containerFiles = scanForFiles(in: userLibrary.appendingPathComponent("Containers"),
                                          pattern: bundleId,
                                          category: .containers)
        files += containerFiles.map { file in
            var mutableFile = file
            mutableFile.isProtected = true
            return mutableFile
        }

        // Group Containers
        files += scanDirectory(userLibrary.appendingPathComponent("Group Containers"),
                              searchTerms: [bundleId],
                              category: .containers)

        // Saved Application State
        files += scanForFiles(in: userLibrary.appendingPathComponent("Saved Application State"),
                             pattern: bundleId,
                             category: .savedState)

        // WebKit
        files += scanForFiles(in: userLibrary.appendingPathComponent("WebKit"),
                             pattern: bundleId,
                             category: .webkit)

        // HTTPStorages
        files += scanForFiles(in: userLibrary.appendingPathComponent("HTTPStorages"),
                             pattern: bundleId,
                             category: .cookies)

        // Cookies
        files += scanForFiles(in: userLibrary.appendingPathComponent("Cookies"),
                             pattern: bundleId,
                             category: .cookies)

        // Application Scripts
        files += scanForFiles(in: userLibrary.appendingPathComponent("Application Scripts"),
                             pattern: bundleId,
                             category: .other)

        // System Library paths (require admin privileges)
        let systemLibrary = URL(fileURLWithPath: "/Library")

        // System Application Support - don't use developerName
        files += scanDirectory(systemLibrary.appendingPathComponent("Application Support"),
                              searchTerms: [appName, bundleId],
                              category: .applicationSupport)

        // Launch Agents (user)
        files += scanForFiles(in: userLibrary.appendingPathComponent("LaunchAgents"),
                             pattern: bundleId,
                             category: .launchAgents)

        // Launch Agents (system)
        files += scanForFiles(in: systemLibrary.appendingPathComponent("LaunchAgents"),
                             pattern: bundleId,
                             category: .launchAgents)

        // Launch Daemons
        files += scanForFiles(in: systemLibrary.appendingPathComponent("LaunchDaemons"),
                             pattern: bundleId,
                             category: .launchDaemons)

        // Privileged Helper Tools
        files += scanForFiles(in: systemLibrary.appendingPathComponent("PrivilegedHelperTools"),
                             pattern: bundleId,
                             category: .launchDaemons)

        // Add the main app itself
        let appSize = calculateDirectorySize(app.path)
        files.insert(RelatedFile(
            path: app.path,
            category: .application,
            size: appSize,
            isSelected: true
        ), at: 0)

        return files
    }

    private func scanDirectory(_ directory: URL, searchTerms: [String], category: FileCategory) -> [RelatedFile] {
        var results: [RelatedFile] = []

        // SECURITY: Include symlink check in properties
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) else { return results }

        for url in contents {
            // SECURITY: Skip symlinks to prevent following malicious links
            if let isSymlink = try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink,
               isSymlink == true {
                continue
            }

            let name = url.lastPathComponent.lowercased()
            for term in searchTerms where !term.isEmpty {
                let searchTerm = term.lowercased()

                // SECURITY: Use more precise matching to avoid false positives
                // Match if: name equals term, starts with term, or ends with term
                // This prevents "Chrome" from matching "ChromiumHelper" in the middle
                let isExactMatch = name == searchTerm
                let isAppMatch = name == searchTerm + ".app"
                let startsWithTerm = name.hasPrefix(searchTerm + ".") ||
                                     name.hasPrefix(searchTerm + "-") ||
                                     name.hasPrefix(searchTerm + "_")
                let endsWithTerm = name.hasSuffix("." + searchTerm) ||
                                   name.hasSuffix("-" + searchTerm) ||
                                   name.hasSuffix("_" + searchTerm)

                // Also match bundle identifiers (com.company.appname format)
                let containsBundleId = searchTerm.contains(".") && name.contains(searchTerm)

                if isExactMatch || isAppMatch || startsWithTerm || endsWithTerm || containsBundleId {
                    let size = calculateDirectorySize(url)
                    results.append(RelatedFile(
                        path: url,
                        category: category,
                        size: size
                    ))
                    break
                }
            }
        }

        return results
    }

    private func scanForFiles(in directory: URL, pattern: String, category: FileCategory) -> [RelatedFile] {
        var results: [RelatedFile] = []

        guard !pattern.isEmpty,
              let contents = try? fileManager.contentsOfDirectory(
                  at: directory,
                  includingPropertiesForKeys: [.isSymbolicLinkKey],
                  options: [.skipsHiddenFiles]
              ) else { return results }

        let searchPattern = pattern.lowercased()

        for url in contents {
            // SECURITY: Skip symlinks to prevent following malicious links
            if let isSymlink = try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink,
               isSymlink == true {
                continue
            }

            let name = url.lastPathComponent.lowercased()

            // SECURITY: Use precise matching for bundle identifiers
            // Bundle IDs are in format: com.company.appname
            // Only match if the name contains the full pattern as a component
            let isExactMatch = name == searchPattern
            let containsPattern = name.contains(searchPattern)

            // For bundle ID matching, ensure it's not a partial match
            // e.g., "com.google.Chrome" should match, but "com.google.ChromeHelper" should be more careful
            if isExactMatch || (containsPattern && searchPattern.contains(".")) {
                let size = calculateDirectorySize(url)
                results.append(RelatedFile(
                    path: url,
                    category: category,
                    size: size
                ))
            }
        }

        return results
    }

    private func calculateDirectorySize(_ url: URL) -> Int64 {
        // SECURITY: Check if the URL is a symlink before processing
        if let isSymlink = try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink,
           isSymlink == true {
            return 0 // Don't follow symlinks
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }

        if !isDirectory.boolValue {
            return (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        }

        var totalSize: Int64 = 0

        // SECURITY: Use options to skip symlinks during enumeration
        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: nil
        ) {
            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(
                    forKeys: [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey]
                ) else { continue }

                // SECURITY: Skip symlinks to prevent following malicious links
                if resourceValues.isSymbolicLink == true {
                    enumerator.skipDescendants()
                    continue
                }

                guard resourceValues.isDirectory == false,
                      let fileSize = resourceValues.fileSize else { continue }
                totalSize += Int64(fileSize)
            }
        }

        return totalSize
    }
}
