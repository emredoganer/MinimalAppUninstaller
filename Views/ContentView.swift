import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppListViewModel
    @State private var showPermissionAlert = false

    var body: some View {
        HSplitView {
            // Left panel - App list
            AppListView()
                .frame(minWidth: 250, maxWidth: 350)

            // Right panel - File details
            DetailView()
                .frame(minWidth: 450)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            if !PermissionManager.shared.hasFullDiskAccess {
                showPermissionAlert = true
            }
        }
        .alert("Full Disk Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                PermissionManager.shared.openFullDiskAccessSettings()
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text("To scan all application files, MinimalAppUninstaller needs Full Disk Access permission.")
        }
        .sheet(isPresented: $viewModel.isRemoving) {
            CleanupProgressView()
        }
        .sheet(isPresented: $viewModel.showRemovalComplete) {
            RemovalCompleteView()
        }
    }
}

struct RemovalCompleteView: View {
    @EnvironmentObject var viewModel: AppListViewModel

    var successCount: Int {
        viewModel.removalResults.filter { $0.success }.count
    }

    var failedCount: Int {
        viewModel.removalResults.filter { !$0.success }.count
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: successCount > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(successCount > 0 ? .green : .red)

            Text("Cleanup Complete")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                if successCount > 0 {
                    Label("\(successCount) files moved to Trash", systemImage: "checkmark")
                        .foregroundColor(.green)
                }
                if failedCount > 0 {
                    Label("\(failedCount) files could not be removed", systemImage: "xmark")
                        .foregroundColor(.red)
                }
            }

            if failedCount > 0 {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.removalResults.filter { !$0.success }, id: \.file.id) { result in
                            Text(result.error?.errorDescription ?? "Unknown error")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxHeight: 100)
            }

            Button("Done") {
                viewModel.showRemovalComplete = false
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(30)
        .frame(width: 350)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppListViewModel())
}
