import Foundation
import TributaryCore

/// Everything Today needs, computed from the unread set. Pure and deterministic so it is
/// testable and so the user can always be told why an item is where it is.
struct TodaySections {
    struct FolderGroup: Identifiable {
        var id: String { name }
        var name: String
        var items: [Item]
    }

    var priority: [Item] = []
    var normal: [FolderGroup] = []
    var ambientCount = 0
    var ambientFeeds: [String] = []
    /// Cluster keyed by its lead item id. Members other than the lead are hidden from the lanes.
    var clusters: [UUID: StoryCluster] = [:]
    var resurface: Item?
    var resurfaceReason: String?

    var isEmpty: Bool { priority.isEmpty && normal.isEmpty && resurface == nil }
    var totalVisible: Int { priority.count + normal.reduce(0) { $0 + $1.items.count } }
}

enum TodayModel {
    static let clusterLimit = 120

    @MainActor
    static func build(unread: [Item], saved: [Item], settings: AppSettings, now: Date = Date()) -> TodaySections {
        var sections = TodaySections()
        let visible = unread.filter { item in
            guard let feed = item.feed, !feed.isMuted else { return item.feed == nil && !item.isSnoozed }
            return !item.isSnoozed
        }

        let capped = applyDailyCaps(visible, now: now)
        let byLane = Dictionary(grouping: capped) { $0.feed?.lane ?? .normal }

        let priority = byLane[.priority] ?? []
        let normal = byLane[.normal] ?? []
        let ambient = byLane[.ambient] ?? []

        // Story clustering across Priority and Normal. Ambient never joins a cluster; it never
        // enters Today at all except as a count.
        // Outbound links are parsed from each body, so the cluster window is capped to keep this
        // rebuild cheap on the main actor.
        let candidates = (priority + normal).prefix(clusterLimit).map { item in
            ClusterCandidate(
                id: item.id.uuidString,
                title: item.title,
                canonicalURL: item.canonicalURL,
                outboundLinks: outboundLinks(item),
                published: item.publishedAt,
                isPriority: item.feed?.lane == .priority
            )
        }
        var hidden = Set<UUID>()
        for cluster in StoryClusterer.clusters(Array(candidates)) {
            guard let lead = UUID(uuidString: cluster.leadID) else { continue }
            sections.clusters[lead] = cluster
            for member in cluster.memberIDs where member != cluster.leadID {
                if let id = UUID(uuidString: member) { hidden.insert(id) }
            }
        }

        sections.priority = priority.filter { !hidden.contains($0.id) }
        let normalVisible = normal.filter { !hidden.contains($0.id) }
        let grouped = Dictionary(grouping: normalVisible) { $0.feed?.folder?.name ?? "Unfiled" }
        sections.normal = grouped
            .map { TodaySections.FolderGroup(name: $0.key, items: $0.value) }
            .sorted { lhs, rhs in
                let l = lhs.items.first?.feed?.folder?.sortOrder ?? Int.max
                let r = rhs.items.first?.feed?.folder?.sortOrder ?? Int.max
                return l == r ? lhs.name < rhs.name : l < r
            }

        sections.ambientCount = ambient.count
        sections.ambientFeeds = Array(Dictionary(grouping: ambient) { $0.feed?.displayTitle ?? "" }
            .sorted { $0.value.count > $1.value.count }
            .prefix(3)
            .map(\.key))

        if settings.resurfacingEnabled {
            let pick = Resurfacer.pick(saved: saved, settings: settings, now: now)
            sections.resurface = pick?.item
            sections.resurfaceReason = pick?.reason
        }
        return sections
    }

    /// "Show me at most N a day from this one." The rest stay in the feed's own view.
    private static func applyDailyCaps(_ items: [Item], now: Date) -> [Item] {
        var counts: [UUID: Int] = [:]
        let dayStart = Calendar.current.startOfDay(for: now)
        return items.filter { item in
            guard let feed = item.feed, feed.dailyCap > 0, item.sortDate >= dayStart else { return true }
            counts[feed.id, default: 0] += 1
            return counts[feed.id]! <= feed.dailyCap
        }
    }

    private static func outboundLinks(_ item: Item) -> [String] {
        guard let html = item.bodyHTML else { return [] }
        return HTMLBlocks.blocks(from: html, baseURL: item.link)
            .flatMap(\.links)
            .map(CanonicalURL.normalize)
    }
}

/// One card in Today, at most one a day, chosen by rule, explained in the card. Dismiss
/// silences it for ninety days. Off switch in Settings.
enum Resurfacer {
    struct Pick {
        var item: Item
        var reason: String
    }

    @MainActor
    static func pick(saved: [Item], settings: AppSettings, now: Date) -> Pick? {
        if let until = settings.resurfaceDismissedUntil, until > now { return nil }
        // Keep the same card for the whole day so it doesn't churn between opens.
        if let last = settings.lastResurfacedAt, Calendar.current.isDate(last, inSameDayAs: now),
           let id = settings.lastResurfacedItemID, let item = saved.first(where: { $0.id.uuidString == id }) {
            return Pick(item: item, reason: reason(for: item, now: now))
        }
        let thirtyDays = now.addingTimeInterval(-30 * 86_400)
        let candidates = saved
            .filter { $0.lastOpenedAt == nil && ($0.savedAt ?? $0.receivedAt) < thirtyDays }
            .sorted { ($0.savedAt ?? $0.receivedAt) < ($1.savedAt ?? $1.receivedAt) }
        guard let item = candidates.first else { return nil }
        settings.lastResurfacedItemID = item.id.uuidString
        settings.lastResurfacedAt = now
        return Pick(item: item, reason: reason(for: item, now: now))
    }

    private static func reason(for item: Item, now: Date) -> String {
        let days = max(1, Int(now.timeIntervalSince(item.savedAt ?? item.receivedAt) / 86_400))
        return "From your Saved · you kept this \(days) days ago"
    }
}
