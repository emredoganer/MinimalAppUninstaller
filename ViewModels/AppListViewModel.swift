import Combine
import SwiftUI

@MainActor
class AppListViewModel: ObservableObject {
    @Published var apps: [InstalledApp] = []
    @Published var filteredApps: [InstalledApp] = []
    @Published var selectedApp: InstalledApp?
    @Published var relatedFiles: [RelatedFile] = []
    @Published var isLoading = false
    @Published var isScanning = false
    @Published var searchText = "" {
        didSet { filterApps() }
    }

    @Published var isRemoving = false
    @Published var removalProgress: (current: Int, total: Int) = (0, 0)
    @Published var removalResults: [RemovalResult] = []
    @Published var showRemovalComplete = false

    private let appScanner = AppScanner.shared
    private let fileScanner = FileScanner.shared
    private let fileRemover = FileRemover.shared

    var totalSelectedSize: Int64 {
        relatedFiles.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)
    }

    var selectedFileCount: Int {
        relatedFiles.filter { $0.isSelected }.count
    }

    var groupedFiles: [FileCategory: [RelatedFile]] {
        Dictionary(grouping: relatedFiles, by: { $0.category })
    }

    init() {
        Task {
            await loadApps()
        }
    }

    func loadApps() async {
        isLoading = true
        apps = await appScanner.scanApplications()
        filterApps()
        isLoading = false
    }

    func selectApp(_ app: InstalledApp) async {
        selectedApp = app
        isScanning = true
        relatedFiles = await fileScanner.scanRelatedFiles(for: app)
        isScanning = false
    }

    func toggleFileSelection(_ file: RelatedFile) {
        if let index = relatedFiles.firstIndex(where: { $0.id == file.id }) {
            relatedFiles[index].isSelected.toggle()
        }
    }

    func selectAllFiles() {
        for index in relatedFiles.indices {
            if !relatedFiles[index].isProtected {
                relatedFiles[index].isSelected = true
            }
        }
    }

    func deselectAllFiles() {
        for index in relatedFiles.indices {
            relatedFiles[index].isSelected = false
        }
    }

    func toggleCategorySelection(_ category: FileCategory) {
        let categoryFiles = relatedFiles.filter { $0.category == category }
        let allSelected = categoryFiles.allSatisfy { $0.isSelected }

        for index in relatedFiles.indices {
            if relatedFiles[index].category == category && !relatedFiles[index].isProtected {
                relatedFiles[index].isSelected = !allSelected
            }
        }
    }

    func removeSelectedFiles() {
        let selectedFiles = relatedFiles.filter { $0.isSelected && !$0.isProtected }
        guard !selectedFiles.isEmpty else { return }

        isRemoving = true
        removalProgress = (0, selectedFiles.count)

        fileRemover.moveToTrash(selectedFiles) { [weak self] current, total in
            self?.removalProgress = (current, total)
        } completion: { [weak self] results in
            self?.removalResults = results
            self?.isRemoving = false
            self?.showRemovalComplete = true

            // Remove successfully deleted files from the list
            let successPaths = Set(results.filter { $0.success }.map { $0.file.path })
            self?.relatedFiles.removeAll { successPaths.contains($0.path) }

            // If the main app was removed, refresh the app list
            if results.contains(where: { $0.success && $0.file.category == .application }) {
                Task { [weak self] in
                    await self?.loadApps()
                    self?.selectedApp = nil
                    self?.relatedFiles = []
                }
            }
        }
    }

    private func filterApps() {
        if searchText.isEmpty {
            filteredApps = apps
        } else {
            filteredApps = apps.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
