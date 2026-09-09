import SwiftData
import SwiftUI

enum TimelineFilter: String, CaseIterable, Identifiable {
    case all, unread, saved
    var id: Self { self }
    var title: String { rawValue.capitalized }
}

/// Everything in chronological order. The "just show me the river" view.
struct TimelineView: View {
    var laneFilter: Lane? = nil
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Item.publishedAt, order: .reverse)]) private var items: [Item]
    @State private var filter: TimelineFilter = .unread

    private var visible: [Item] {
        items.filter { item in
            if let laneFilter, item.feed?.lane != laneFilter { return false }
            if item.feed?.isMuted == true { return false }
            switch filter {
            case .all: return true
            case .unread: return !item.isRead
            case .saved: return item.isSaved
            }
        }
    }

    private var days: [(day: Date, items: [Item])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: visible.prefix(400)) { calendar.startOfDay(for: $0.sortDate) }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0]!) }
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("Filter", selection: $filter) {
                    ForEach(TimelineFilter.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .rowStyle()

                if visible.isEmpty {
                    ContentUnavailableView("Nothing here", systemImage: "clock", description: Text("Change the filter or pull to refresh."))
                        .rowStyle()
                }

                ForEach(days, id: \.day) { day in
                    LaneHeader(title: day.day.formatted(.dateTime.weekday(.wide).day().month(.wide)), count: day.items.count).rowStyle()
                    ForEach(day.items) { item in
                        NavigationLink(value: item) {
                            ArticleCard(item: item, size: .standard)
                        }
                        .rowStyle()
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button { ItemActions.toggleRead(item, in: context) } label: { Label("Read", systemImage: "checkmark") }
                                .tint(DS.Color.Status.success)
                        }
                        .swipeActions(edge: .trailing) {
                            Button { ItemActions.toggleSaved(item, in: context) } label: { Label("Save", systemImage: "bookmark") }
                                .tint(DS.Color.Interactive.primary)
                        }
                        .contextMenu { ItemContextMenu(item: item) }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.horizontal, Spacing.base, for: .scrollContent)
            .contentMargins(.bottom, Spacing.section, for: .scrollContent)
            .background(DS.Color.Background.primary)
            .navigationTitle(laneFilter == .ambient ? "Ambient" : "Timeline")
            .navigationDestination(for: Item.self) { ReaderView(item: $0) }
        }
    }
}
