import Foundation
import SwiftData
import TributaryCore

/// Priority lanes decide how Today is ordered. User-assigned per feed, default Normal.
enum Lane: String, Codable, CaseIterable, Sendable, Identifiable {
    case priority
    case normal
    case ambient

    var id: String { rawValue }

    var title: String {
        switch self {
        case .priority: "Priority"
        case .normal: "Normal"
        case .ambient: "Ambient"
        }
    }

    var explanation: String {
        switch self {
        case .priority: "Never miss it. Always expanded, always first, can notify."
        case .normal: "Grouped by folder, most recent first."
        case .ambient: "High-volume or low-stakes. Collapsed to a count, never notifies."
        }
    }
}

// CloudKit-compatible SwiftData: no unique constraints, every stored property has a default,
// every relationship is optional. Portability keys (canonicalURL, guid) ride alongside the
// SwiftData identity so the archive is a projection of these tables.

@Model
final class Folder {
    var id: UUID = UUID()
    var name: String = ""
    var sortOrder: Int = 0
    @Relationship(deleteRule: .nullify, inverse: \Feed.folder) var feeds: [Feed]? = []

    init(name: String, sortOrder: Int = 0) {
        self.name = name
        self.sortOrder = sortOrder
    }
}

@Model
final class Feed {
    var id: UUID = UUID()
    var url: String = ""
    var canonicalURL: String = ""
    var title: String = ""
    var customTitle: String?
    var siteURL: String?
    var iconURL: String?
    var hubURL: String?
    var formatRaw: String = FeedFormat.rss.rawValue
    var laneRaw: String = Lane.normal.rawValue
    var isMuted: Bool = false
    /// Items per day admitted into Today. Zero means no cap.
    var dailyCap: Int = 0
    var etag: String?
    var lastModified: String?
    var lastFetchedAt: Date?
    var lastSuccessAt: Date?
    var lastPostedAt: Date?
    var errorCount: Int = 0
    var lastError: String?
    var fetchIntervalSeconds: Int = 3600
    var nextFetchAt: Date?
    var addedAt: Date = Date()
    var sortOrder: Int = 0
    var folder: Folder?
    @Relationship(deleteRule: .cascade, inverse: \Item.feed) var items: [Item]? = []

    init(url: String, title: String) {
        self.url = url
        self.canonicalURL = CanonicalURL.normalize(url)
        self.title = title
    }

    var lane: Lane {
        get { Lane(rawValue: laneRaw) ?? .normal }
        set { laneRaw = newValue.rawValue }
    }

    var format: FeedFormat {
        get { FeedFormat(rawValue: formatRaw) ?? .rss }
        set { formatRaw = newValue.rawValue }
    }

    var displayTitle: String {
        let custom = customTitle?.trimmingCharacters(in: .whitespaces) ?? ""
        if !custom.isEmpty { return custom }
        if !title.isEmpty { return title }
        return URL(string: url)?.host() ?? url
    }

    var hostName: String? { URL(string: siteURL ?? url)?.host() }

    /// Stale means nothing new in 90 days. Shown in feed health and subscription hygiene.
    var isStale: Bool {
        guard let last = lastPostedAt else { return false }
        return Date().timeIntervalSince(last) > 90 * 86_400
    }

    var hasError: Bool { errorCount > 0 }
}

@Model
final class Item {
    var id: UUID = UUID()
    var guid: String = ""
    var fingerprint: String = ""
    var url: String?
    var canonicalURL: String?
    var title: String = ""
    var author: String?
    var publishedAt: Date?
    var updatedAt: Date?
    var receivedAt: Date = Date()
    var summaryHTML: String?
    var contentHTML: String?
    /// Extracted article as JSON-encoded [ContentBlock], filled on demand for truncated feeds.
    var extractedBlocksData: Data?
    var contentText: String = ""
    var imageURL: String?
    var wordCount: Int = 0
    var isRead: Bool = false
    var readAt: Date?
    var isSaved: Bool = false
    var savedAt: Date?
    var lastOpenedAt: Date?
    var readPosition: Double = 0
    var snoozedUntil: Date?
    var tags: [String] = []
    var note: String?
    var updateCount: Int = 0
    var feed: Feed?
    @Relationship(deleteRule: .cascade, inverse: \Highlight.item) var highlights: [Highlight]? = []

    init(guid: String, title: String) {
        self.guid = guid
        self.title = title
    }

    var link: URL? { url.flatMap(URL.init(string:)) }
    var cover: URL? { imageURL.flatMap(URL.init(string:)) }
    var readingMinutes: Int { ReadingTime.minutes(wordCount: wordCount) }
    var sortDate: Date { publishedAt ?? receivedAt }
    var isSnoozed: Bool { snoozedUntil.map { $0 > Date() } ?? false }
    var sourceTitle: String { feed?.displayTitle ?? link?.host() ?? "Saved link" }

    /// The best body available to render, as HTML.
    var bodyHTML: String? {
        if let content = contentHTML, !content.isEmpty { return content }
        if let summary = summaryHTML, !summary.isEmpty { return summary }
        return nil
    }

    var extractedBlocks: [ContentBlock]? {
        get { extractedBlocksData.flatMap { try? JSONDecoder().decode([ContentBlock].self, from: $0) } }
        set { extractedBlocksData = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }

    /// A feed body under ~600 characters is a teaser; the reader offers extraction.
    var looksTruncated: Bool { contentText.count < 600 }
}

@Model
final class Highlight {
    var id: UUID = UUID()
    var quote: String = ""
    var note: String?
    var position: Double = 0
    var createdAt: Date = Date()
    var item: Item?

    init(quote: String, note: String? = nil, position: Double = 0) {
        self.quote = quote
        self.note = note
        self.position = position
    }
}

/// An unnamed group of a few saved items. Up Next is the one stack that is ordered.
@Model
final class ItemStack {
    var id: UUID = UUID()
    var name: String?
    var createdAt: Date = Date()
    var itemIDs: [UUID] = []
    var isUpNext: Bool = false

    init(name: String? = nil, itemIDs: [UUID] = [], isUpNext: Bool = false) {
        self.name = name
        self.itemIDs = itemIDs
        self.isUpNext = isUpNext
    }

    var displayName: String {
        let trimmed = name?.trimmingCharacters(in: .whitespaces) ?? ""
        if !trimmed.isEmpty { return trimmed }
        return isUpNext ? "Up Next" : "Stack"
    }
}
