import SwiftUI

struct DetailView: View {
    @EnvironmentObject var viewModel: AppListViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            if let app = viewModel.selectedApp {
                // Header
                HStack(spacing: 12) {
                    Image(nsImage: app.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(app.bundleIdentifier)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if !viewModel.relatedFiles.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(viewModel.formattedTotalSize)
                                .font(.title3)
                                .fontWeight(.medium)

                            Text("\(viewModel.selectedFileCount) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                // File list
                if viewModel.isScanning {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Scanning for related files...")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if viewModel.relatedFiles.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "doc.badge.gearshape")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No related files found")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Selection controls
                    HStack {
                        Button("Select All") {
                            viewModel.selectAllFiles()
                        }
                        .buttonStyle(.link)

                        Text("·")
                            .foregroundColor(.secondary)

                        Button("Deselect All") {
                            viewModel.deselectAllFiles()
                        }
                        .buttonStyle(.link)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Divider()

                    // Grouped file list
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(FileCategory.allCases, id: \.self) { category in
                                if let files = viewModel.groupedFiles[category], !files.isEmpty {
                                    Section {
                                        ForEach(files) { file in
                                            FileRowView(file: file) {
                                                viewModel.toggleFileSelection(file)
                                            }
                                            Divider()
                                                .padding(.leading, 40)
                                        }
                                    } header: {
                                        CategoryHeaderView(
                                            category: category,
                                            files: files,
                                            onToggle: { viewModel.toggleCategorySelection(category) }
                                        )
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // Footer with uninstall button
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total: \(viewModel.formattedTotalSize)")
                                .font(.headline)
                            Text("\(viewModel.selectedFileCount) of \(viewModel.relatedFiles.count) files selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Move to Trash", systemImage: "trash")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(viewModel.selectedFileCount == 0)
                        .confirmationDialog(
                            "Move \(viewModel.selectedFileCount) files to Trash?",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Move to Trash", role: .destructive) {
                                viewModel.removeSelectedFiles()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will move \(viewModel.formattedTotalSize) of files to Trash. You can restore them from Trash if needed.")
                        }
                    }
                    .padding()
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "arrow.left.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("Select an app to view its files")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Choose an application from the list to see all related files that can be removed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CategoryHeaderView: View {
    let category: FileCategory
    let files: [RelatedFile]
    let onToggle: () -> Void

    var categorySize: Int64 {
        files.reduce(0) { $0 + $1.size }
    }

    var allSelected: Bool {
        files.allSatisfy { $0.isSelected }
    }

    var body: some View {
        HStack {
            Button {
                onToggle()
            } label: {
                Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(allSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: category.icon)
                .foregroundColor(category.color)
                .frame(width: 20)

            Text(category.rawValue)
                .fontWeight(.medium)

            Spacer()

            Text("\(files.count) files")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(ByteCountFormatter.string(fromByteCount: categorySize, countStyle: .file))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

#Preview {
    DetailView()
        .environmentObject(AppListViewModel())
        .frame(width: 500, height: 600)
}
