import Foundation

/// Which syntax the feed was written in. Kept on the parsed feed so the app can
/// show it in feed health and the archive can record it.
public enum FeedFormat: String, Sendable, Codable, Hashable {
    case rss
    case atom
    case jsonFeed
}

public struct Enclosure: Sendable, Hashable, Codable {
    public var url: URL
    public var mimeType: String?
    public var length: Int?

    public init(url: URL, mimeType: String? = nil, length: Int? = nil) {
        self.url = url
        self.mimeType = mimeType
        self.length = length
    }

    public var isImage: Bool { mimeType?.hasPrefix("image/") == true }
    public var isAudio: Bool { mimeType?.hasPrefix("audio/") == true }
    public var isVideo: Bool { mimeType?.hasPrefix("video/") == true }
}

/// One entry from a feed, normalized across RSS 2.0, RSS 1.0 (RDF), Atom, and JSON Feed.
public struct ParsedItem: Sendable, Hashable, Codable {
    /// Stable identity within the feed. Falls back to the link, then to a hash of title and date.
    public var guid: String
    public var url: URL?
    public var title: String
    public var author: String?
    public var published: Date?
    public var updated: Date?
    public var summaryHTML: String?
    public var contentHTML: String?
    public var imageURL: URL?
    public var enclosures: [Enclosure]
    public var categories: [String]

    public init(
        guid: String,
        url: URL? = nil,
        title: String,
        author: String? = nil,
        published: Date? = nil,
        updated: Date? = nil,
        summaryHTML: String? = nil,
        contentHTML: String? = nil,
        imageURL: URL? = nil,
        enclosures: [Enclosure] = [],
        categories: [String] = []
    ) {
        self.guid = guid
        self.url = url
        self.title = title
        self.author = author
        self.published = published
        self.updated = updated
        self.summaryHTML = summaryHTML
        self.contentHTML = contentHTML
        self.imageURL = imageURL
        self.enclosures = enclosures
        self.categories = categories
    }

    /// The richest body available: full content when the feed carries it, otherwise the summary.
    public var bestHTML: String? { contentHTML ?? summaryHTML }

    /// True when the feed only ships a teaser and the app should extract the article from the page.
    public var looksTruncated: Bool {
        guard let html = bestHTML else { return true }
        return HTMLText.plainText(html).count < 600
    }
}

public struct ParsedFeed: Sendable, Hashable, Codable {
    public var title: String
    public var siteURL: URL?
    public var feedDescription: String?
    public var iconURL: URL?
    /// WebSub hub, when the feed advertises one. Server-side only; the app ignores it.
    public var hubURL: URL?
    public var format: FeedFormat
    public var items: [ParsedItem]

    public init(
        title: String,
        siteURL: URL? = nil,
        feedDescription: String? = nil,
        iconURL: URL? = nil,
        hubURL: URL? = nil,
        format: FeedFormat,
        items: [ParsedItem]
    ) {
        self.title = title
        self.siteURL = siteURL
        self.feedDescription = feedDescription
        self.iconURL = iconURL
        self.hubURL = hubURL
        self.format = format
        self.items = items
    }

    /// Posts per week, measured over the items the feed currently carries. Used by feed preview
    /// before subscribing and by the adaptive fetch scheduler.
    public var postsPerWeek: Double {
        let dates = items.compactMap(\.published).sorted()
        guard let first = dates.first, let last = dates.last, dates.count > 1 else { return 0 }
        let span = last.timeIntervalSince(first)
        guard span > 0 else { return Double(dates.count) }
        return Double(dates.count - 1) / span * 7 * 86_400
    }

    /// Share of items that carry more than a teaser. Shown in feed preview as "full text" or "stubs".
    public var fullTextRatio: Double {
        guard !items.isEmpty else { return 0 }
        let full = items.filter { !$0.looksTruncated }.count
        return Double(full) / Double(items.count)
    }
}

public enum FeedParserError: Error, Sendable, Equatable {
    case empty
    case unrecognizedFormat
    case malformed(String)
}
