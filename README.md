# MinimalAppUninstaller

A clean, minimal macOS app uninstaller built with SwiftUI. Completely remove applications and all their related files.

<img width="1009" height="632" alt="MinimalAppUninstaller" src="https://github.com/user-attachments/assets/835ab9c0-ea78-4182-8570-55d45a6b3be2" />

## Features

- Scan all installed applications
- Find related files (preferences, caches, support files, logs, etc.)
- View file sizes by category
- Move files to Trash safely
- Clean, minimal native UI

## Installation

### Requirements

- macOS 13.0 (Ventura) or later

### Build from Source

Download the latest release from [Releases](https://github.com/emredoganer/MinimalAppUninstaller/releases) page, or clone the repository:

```bash
git clone https://github.com/emredoganer/MinimalAppUninstaller.git
cd MinimalAppUninstaller
```

**Option 1:** Build using the build script:

```bash
./build.sh
```

The app will be at `dist/MinimalAppUninstaller.app`

**Option 2:** Open `MinimalAppUninstaller.xcodeproj` in Xcode and build with `⌘R`.

## Permissions

This app requires **Full Disk Access** to scan directories like:
- ~/Library/Containers
- ~/Library/Group Containers
- Some system directories

To grant Full Disk Access:
1. Open **System Settings** > **Privacy & Security** > **Full Disk Access**
2. Add MinimalAppUninstaller to the list

Without FDA, some files may not be detected.

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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Built with SwiftUI for macOS.
