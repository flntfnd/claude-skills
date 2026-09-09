import SwiftUI

enum AppTab: String, Hashable {
    case today, timeline, feeds, saved, search
}

/// Five destinations, the iOS 26+ floating glass tab bar that minimizes on scroll, the
/// search role that places its own floating button, and the sidebar-adaptable style so
/// iPad gets a sidebar without a second navigation model.
struct RootView: View {
    @Environment(RefreshCoordinator.self) private var refresher
    @State private var selection: AppTab = .today
    @State private var didLaunchRefresh = false

    var body: some View {
        TabView(selection: $selection) {
            Tab("Today", systemImage: "sun.max", value: .today) { TodayView() }
            Tab("Timeline", systemImage: "clock", value: .timeline) { TimelineView() }
            Tab("Feeds", systemImage: "dot.radiowaves.up.forward", value: .feeds) { FeedsView() }
            Tab("Saved", systemImage: "bookmark", value: .saved) { SavedView() }
            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) { SearchView() }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .task {
            guard !didLaunchRefresh else { return }
            didLaunchRefresh = true
            await refresher.refreshAll(reason: .launch)
        }
        .onOpenURL { url in
            // tributary://open?tab=saved, feed://…, or a pasted feed URL from another app.
            if url.scheme == "tributary" {
                if let tab = url.queryValue("tab").flatMap(AppTab.init(rawValue:)) { selection = tab }
            } else {
                PendingSubscription.shared.url = url
                selection = .feeds
            }
        }
    }
}

/// A URL handed to the app that the Feeds tab should offer to subscribe to.
@MainActor
@Observable
final class PendingSubscription {
    static let shared = PendingSubscription()
    var url: URL?
}

extension URL {
    func queryValue(_ name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == name }?.value
    }
}
