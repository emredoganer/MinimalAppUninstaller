import SwiftUI

struct AppListView: View {
    @EnvironmentObject var viewModel: AppListViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search apps...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // App list
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading apps...")
                Spacer()
            } else if viewModel.filteredApps.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "app.dashed")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No apps found")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(viewModel.filteredApps, selection: Binding(
                    get: { viewModel.selectedApp },
                    set: { app in
                        if let app = app {
                            Task {
                                await viewModel.selectApp(app)
                            }
                        }
                    }
                )) { app in
                    AppRowView(app: app)
                        .tag(app)
                }
                .listStyle(.sidebar)
            }

            Divider()

            // Footer
            HStack {
                Text("\(viewModel.filteredApps.count) apps")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    Task {
                        await viewModel.loadApps()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Refresh app list")
            }
            .padding(8)
        }
    }
}

#Preview {
    AppListView()
        .environmentObject(AppListViewModel())
        .frame(width: 280, height: 500)
}
