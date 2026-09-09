import BackgroundTasks
import SwiftData
import SwiftUI

@main
struct TributaryApp: App {
    private let container: ModelContainer
    private let settings = AppSettings.shared
    private let refresher: RefreshCoordinator

    init() {
        let schema = Schema([Feed.self, Folder.self, Item.self, Highlight.self, ItemStack.self])
        // Local mode keeps everything on device and syncs through CloudKit's private database.
        // The archive mirror in iCloud Drive is a separate, human-readable copy (ArchiveMirror).
        let cloud: ModelConfiguration.CloudKitDatabase = AppSettings.shared.iCloudSyncEnabled ? .automatic : .none
        let configuration = ModelConfiguration("Tributary", schema: schema, cloudKitDatabase: cloud)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // A corrupt store on launch is unrecoverable without user intent. Fall back to a
            // local-only store so the app opens, and surface the problem in Settings.
            let fallback = ModelConfiguration("Tributary", schema: schema, cloudKitDatabase: .none)
            do {
                container = try ModelContainer(for: schema, configurations: [fallback])
                AppSettings.shared.storeFailureMessage = "iCloud sync could not start: \(error.localizedDescription)"
            } catch {
                fatalError("Could not open the local store: \(error)")
            }
        }
        refresher = RefreshCoordinator(container: container)
        SharedContainer.live = container
    }

    var body: some Scene {
        WindowGroup {
            RootGate()
                .environment(settings)
                .environment(refresher)
                .modelContainer(container)
                .tint(DS.Color.Interactive.primary)
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.identifier)) {
            await refresher.refreshAll(reason: .background)
            BackgroundRefresh.scheduleNext()
        }
    }
}

/// Onboarding until a storage mode is chosen, the app after that.
private struct RootGate: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        if settings.storageMode == nil {
            OnboardingView()
        } else {
            RootView()
                .task { BackgroundRefresh.scheduleNext() }
        }
    }
}
