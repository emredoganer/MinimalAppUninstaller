import SwiftUI

@main
struct MinimalAppUninstallerApp: App {
    @StateObject private var appListViewModel = AppListViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appListViewModel)
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
