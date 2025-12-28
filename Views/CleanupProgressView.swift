import SwiftUI

struct CleanupProgressView: View {
    @EnvironmentObject var viewModel: AppListViewModel

    var progress: Double {
        guard viewModel.removalProgress.total > 0 else { return 0 }
        return Double(viewModel.removalProgress.current) / Double(viewModel.removalProgress.total)
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash.circle")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text("Removing Files...")
                .font(.title2)
                .fontWeight(.semibold)

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 200)

            Text("\(viewModel.removalProgress.current) of \(viewModel.removalProgress.total)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Moving files to Trash...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(width: 300)
        .interactiveDismissDisabled()
    }
}

#Preview {
    CleanupProgressView()
        .environmentObject(AppListViewModel())
}
