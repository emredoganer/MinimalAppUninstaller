import AppKit
import Foundation

class AppScanner {
    static let shared = AppScanner()

    private init() {}

    func scanApplications() async -> [InstalledApp] {
        var apps: [InstalledApp] = []
        let fileManager = FileManager.default

        let applicationPaths = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications")
        ]

        for basePath in applicationPaths {
            guard let contents = try? fileManager.contentsOfDirectory(
                at: basePath,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in contents {
                if url.pathExtension == "app" {
                    if let app = createInstalledApp(from: url) {
                        apps.append(app)
                    }
                }

                // Check subdirectories (for apps like Setapp)
                if let isDir = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory,
                   isDir == true,
                   url.pathExtension != "app" {
                    if let subContents = try? fileManager.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: nil,
                        options: [.skipsHiddenFiles]
                    ) {
                        for subUrl in subContents where subUrl.pathExtension == "app" {
                            if let app = createInstalledApp(from: subUrl) {
                                apps.append(app)
                            }
                        }
                    }
                }
            }
        }

        return apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    private func createInstalledApp(from url: URL) -> InstalledApp? {
        let infoPlistURL = url.appendingPathComponent("Contents/Info.plist")

        guard let plistData = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }

        let bundleIdentifier = plist["CFBundleIdentifier"] as? String ?? ""
        let bundleName = plist["CFBundleName"] as? String
            ?? plist["CFBundleDisplayName"] as? String
            ?? url.deletingPathExtension().lastPathComponent

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)

        return InstalledApp(
            name: bundleName,
            bundleIdentifier: bundleIdentifier,
            path: url,
            icon: icon
        )
    }
}
