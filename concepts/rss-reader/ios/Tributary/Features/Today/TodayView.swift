import SwiftData
import SwiftUI
import TributaryCore

/// The home screen. Unread grouped by lane, story clusters collapsed to one row, the
/// resurfacing card, and Ambient as a count. Rows live in a plain List so swipe actions
/// are the system's own.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(RefreshCoordinator.self) private var refresher
    @Query(filter: #Predicate<Item> { !$0.isRead }, sort: [SortDescriptor(\Item.publishedAt, order: .reverse)])
    private var unread: [Item]
    @Query(filter: #Predicate<Item> { $0.isSaved }) private var saved: [Item]
    @Query private var feeds: [Feed]
    @State private var sections = TodaySections()
    @State private var showAmbient = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if feeds.isEmpty {
                    ContentUnavailableView {
                        Label("No feeds yet", systemImage: "dot.radiowaves.up.forward")
                    } description: {
                        Text("Add a feed or import an OPML file from the Feeds tab.")
                    }
                } else if refresher.isRefreshing, unread.isEmpty {
                    loading
                } else if sections.isEmpty, sections.ambientCount == 0 {
                    caughtUp
                } else {
                    list
                }
            }
            .background(DS.Color.Background.primary)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await refresher.refreshAll(reason: .userPull) } } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(refresher.isRefreshing)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Mark Today as read", systemImage: "checkmark.circle") { markAllRead() }
                        Toggle("Show resurfaced saves", isOn: Bindable(settings).resurfacingEnabled)
                        Divider()
                        Button("Settings", systemImage: "gearshape") { showSettings = true }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .refreshable { await refresher.refreshAll(reason: .userPull) }
            .navigationDestination(for: Item.self) { ReaderView(item: $0) }
            .navigationDestination(isPresented: $showAmbient) { TimelineView(laneFilter: .ambient) }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .onChange(of: unread, initial: true) { _, _ in rebuild() }
            .onChange(of: settings.resurfacingEnabled) { _, _ in rebuild() }
        }
    }

    private var list: some View {
        List {
            if let error = refresher.lastError {
                ErrorBanner(title: error, message: "Showing what was synced\(settings.lastRefreshAt.map { " at " + $0.formatted(date: .omitted, time: .shortened) } ?? "").") {
                    Task { await refresher.refreshAll(reason: .userPull, force: true) }
                }
                .rowStyle()
            }

            if !sections.priority.isEmpty {
                LaneHeader(title: "Priority", count: sections.priority.count).rowStyle()
                ForEach(Array(sections.priority.enumerated()), id: \.element.id) { index, item in
                    row(item, size: index == 0 ? .large : .standard)
                }
            }

            if let resurface = sections.resurface {
                NavigationLink(value: resurface) {
                    ResurfaceCard(item: resurface, reason: sections.resurfaceReason ?? "From your Saved") {
                        settings.resurfaceDismissedUntil = Date().addingTimeInterval(90 * 86_400)
                        rebuild()
                    }
                }
                .rowStyle()
            }

            ForEach(sections.normal) { group in
                LaneHeader(title: group.name, count: group.items.count).rowStyle()
                ForEach(group.items) { item in
                    row(item, size: .standard)
                }
            }

            if sections.ambientCount > 0 {
                LaneHeader(title: "Ambient", count: nil).rowStyle()
                Button { showAmbient = true } label: {
                    AmbientRow(count: sections.ambientCount, feeds: sections.ambientFeeds)
                }
                .buttonStyle(.plain)
                .rowStyle()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.horizontal, Spacing.base, for: .scrollContent)
        .contentMargins(.bottom, Spacing.section, for: .scrollContent)
    }

    private func row(_ item: Item, size: CardSize) -> some View {
        NavigationLink(value: item) {
            ArticleCard(item: item, size: size, clusterCount: sections.clusters[item.id]?.count)
        }
        .rowStyle()
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { ItemActions.toggleRead(item, in: context) } label: {
                Label("Read", systemImage: "checkmark")
            }
            .tint(DS.Color.Status.success)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button { ItemActions.toggleSaved(item, in: context) } label: {
                Label(item.isSaved ? "Unsave" : "Save", systemImage: item.isSaved ? "bookmark.slash" : "bookmark")
            }
            .tint(DS.Color.Interactive.primary)
            Button { ItemActions.snooze(item, until: SnoozeChoice.tomorrow.date, in: context) } label: {
                Label("Snooze", systemImage: "moon.zzz")
            }
            .tint(DS.Color.Status.info)
        }
        .contextMenu { ItemContextMenu(item: item) }
    }

    private var loading: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                LaneHeader(title: "Priority", count: nil)
                ForEach(0..<5, id: \.self) { _ in SkeletonRow() }
                Text("Refreshing \(feeds.count) feeds…")
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.tertiary)
            }
            .padding(.horizontal, Spacing.base)
        }
    }

    private var caughtUp: some View {
        ContentUnavailableView {
            Label("You’re caught up", systemImage: "checkmark")
        } description: {
            Text("Nothing new in Priority or Normal\(settings.lastRefreshAt.map { " since " + $0.formatted(date: .omitted, time: .shortened) } ?? "").")
        }
    }

    private func rebuild() {
        sections = TodayModel.build(unread: unread, saved: saved, settings: settings)
    }

    private func markAllRead() {
        withAnimation(Motion.readState) {
            for item in sections.priority { ItemActions.markRead(item) }
            for group in sections.normal { for item in group.items { ItemActions.markRead(item) } }
            try? context.save()
        }
    }
}

extension View {
    /// Card rows in a plain List: no separators, no default inset, transparent background.
    func rowStyle() -> some View {
        listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: Spacing.xs, leading: 0, bottom: Spacing.xs, trailing: 0))
    }
}

enum SnoozeChoice: CaseIterable, Identifiable {
    case tonight, tomorrow, weekend
    var id: Self { self }

    var title: String {
        switch self {
        case .tonight: "Tonight"
        case .tomorrow: "Tomorrow morning"
        case .weekend: "This weekend"
        }
    }

    var date: Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .tonight:
            return calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now).map { $0 > now ? $0 : $0.addingTimeInterval(86_400) } ?? now
        case .tomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        case .weekend:
            var next = now
            while calendar.component(.weekday, from: next) != 7 { next = calendar.date(byAdding: .day, value: 1, to: next) ?? next }
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: next) ?? next
        }
    }
}

/// Shared item mutations so Today, Timeline, Search, and the reader agree on what read, save,
/// and snooze mean.
@MainActor
enum ItemActions {
    static func markRead(_ item: Item) {
        guard !item.isRead else { return }
        item.isRead = true
        item.readAt = Date()
    }

    static func toggleRead(_ item: Item, in context: ModelContext) {
        withAnimation(Motion.readState) {
            item.isRead.toggle()
            item.readAt = item.isRead ? Date() : nil
            try? context.save()
        }
    }

    static func toggleSaved(_ item: Item, in context: ModelContext) {
        withAnimation(Motion.readState) {
            item.isSaved.toggle()
            item.savedAt = item.isSaved ? Date() : nil
            try? context.save()
        }
        if AppSettings.shared.archiveMirrorEnabled {
            let container = context.container
            Task { await ArchiveMirror.shared.scheduleWrite(container: container) }
        }
    }

    static func snooze(_ item: Item, until date: Date, in context: ModelContext) {
        withAnimation(Motion.readState) {
            item.snoozedUntil = date
            try? context.save()
        }
    }

    static func addToUpNext(_ item: Item, in context: ModelContext) {
        let stacks = (try? context.fetch(FetchDescriptor<ItemStack>(predicate: #Predicate { $0.isUpNext }))) ?? []
        let queue = stacks.first ?? {
            let created = ItemStack(name: "Up Next", isUpNext: true)
            context.insert(created)
            return created
        }()
        if !queue.itemIDs.contains(item.id) { queue.itemIDs.append(item.id) }
        try? context.save()
    }
}

struct ItemContextMenu: View {
    @Environment(\.modelContext) private var context
    let item: Item

    var body: some View {
        Button(item.isRead ? "Mark unread" : "Mark read", systemImage: item.isRead ? "circle" : "checkmark.circle") {
            ItemActions.toggleRead(item, in: context)
        }
        Button(item.isSaved ? "Remove from Saved" : "Save", systemImage: item.isSaved ? "bookmark.slash" : "bookmark") {
            ItemActions.toggleSaved(item, in: context)
        }
        Button("Add to Up Next", systemImage: "text.line.first.and.arrowtriangle.forward") {
            ItemActions.addToUpNext(item, in: context)
        }
        Menu("Snooze", systemImage: "moon.zzz") {
            ForEach(SnoozeChoice.allCases) { choice in
                Button(choice.title) { ItemActions.snooze(item, until: choice.date, in: context) }
            }
        }
        if let link = item.link {
            ShareLink(item: link) { Label("Share", systemImage: "square.and.arrow.up") }
            Link(destination: link) { Label("Open in Safari", systemImage: "safari") }
        }
    }
}
