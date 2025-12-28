# MinimalAppUninstaller

A clean, minimal macOS app uninstaller built with SwiftUI. Completely remove applications and all their related files.

<img width="1009" height="632" alt="MinimalAppUninstaller" src="https://github.com/user-attachments/assets/835ab9c0-ea78-4182-8570-55d45a6b3be2" />

## Features

- Scan all installed applications
- Find related files (preferences, caches, support files, etc.)
- View file sizes by category
- Move files to Trash safely
- Clean, minimal UI

## Requirements

- macOS 13.0 (Ventura) or later
- Full Disk Access permission (for scanning protected directories)

## Building

### Option 1: Using Xcode (Recommended)

1. Open Xcode
2. File > New > Project
3. Select macOS > App
4. Name it "MinimalAppUninstaller"
5. Delete the auto-generated files
6. Drag all the Swift files from this folder into the project
7. Configure signing & capabilities:
   - Turn OFF "App Sandbox"
   - Add "MinimalAppUninstaller.entitlements"
8. Build and run

### Option 2: Using XcodeGen

If you have [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed:

```bash
# Install xcodegen if needed
brew install xcodegen

# Generate Xcode project
cd ~/ClaudeProject/MinimalAppUninstaller
xcodegen generate

# Open the project
open MinimalAppUninstaller.xcodeproj
```

## Project Structure

```
MinimalAppUninstaller/
├── MinimalAppUninstallerApp.swift   # App entry point
├── Models/
│   ├── InstalledApp.swift           # App data model
│   ├── RelatedFile.swift            # File data model
│   └── FileCategory.swift           # File categories
├── Services/
│   ├── AppScanner.swift             # Scan /Applications
│   ├── FileScanner.swift            # Find related files
│   ├── FileRemover.swift            # Remove files
│   └── PermissionManager.swift      # Permission handling
├── ViewModels/
│   └── AppListViewModel.swift       # Main view model
├── Views/
│   ├── ContentView.swift            # Main view
│   ├── AppListView.swift            # App list (left panel)
│   ├── AppRowView.swift             # App list row
│   ├── DetailView.swift             # File details (right panel)
│   ├── FileRowView.swift            # File list row
│   └── CleanupProgressView.swift    # Removal progress
└── Extensions/
    ├── URL+FileSize.swift           # File size helpers
    └── NSImage+AppIcon.swift        # Image helpers
```

## Permissions

This app requires **Full Disk Access** to scan directories like:
- ~/Library/Containers
- ~/Library/Group Containers
- Some system directories

Without FDA, some files may not be detected.

## License

MIT License

## Credits

Built with SwiftUI for macOS.
