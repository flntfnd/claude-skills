import Foundation
import SwiftData
import TributaryCore

/// What the Add Feed sheet shows before the user commits: the parsed feed, its cadence,
/// and whether it ships full text. Subscribing is a decision, and this is the information
/// to make it (CONCEPT.md, "feed preview before subscribing").
struct FeedPreview: Sendable, Identifiable {
    var id: String { url.absoluteString }
    var url: URL
    var parsed: ParsedFeed

    var postsPerWeek: Double { parsed.postsPerWeek }
    var fullTextRatio: Double { parsed.fullTextRatio }
    var latest: Date? { parsed.items.compactMap(\.published).max() }
}

enum SubscribeError: LocalizedError {
    case invalidInput
    case nothingFound
    case alreadySubscribed(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput: "That doesn’t look like a web address."
        case .nothingFound: "No feed found at that address, or on the page it points to."
        case let .alreadySubscribed(title): "You already follow \(title)."
        }
    }
}

enum FeedSubscriber {
    /// Turns whatever the user typed into feed previews. Tries the URL as a feed, then platform
    /// patterns (YouTube, Substack, GitHub…), then advertised feeds on the page, then common paths.
    static func discover(input: String) async throws -> [FeedPreview] {
        guard let url = CanonicalURL.fetchable(fromInput: input) else { throw SubscribeError.invalidInput }

        if let preview = try? await preview(url) { return [preview] }

        if let platform = FeedDiscovery.platformFeed(for: url), let preview = try? await preview(platform) {
            return [preview]
        }

        var found: [FeedPreview] = []
        if let html = try? await FeedFetcher.fetchPage(url) {
            for candidate in FeedDiscovery.advertisedFeeds(inHTML: html, baseURL: url).prefix(4) {
                if let preview = try? await preview(candidate) { found.append(preview) }
            }
        }
        if found.isEmpty {
            for guess in FeedDiscovery.guesses(for: url).prefix(6) {
                if let preview = try? await preview(guess) {
                    found.append(preview)
                    break
                }
            }
        }
        guard !found.isEmpty else { throw SubscribeError.nothingFound }
        return found
    }

    static func preview(_ url: URL) async throws -> FeedPreview {
        let parsed = try await FeedFetcher.fetchFeed(url)
        return FeedPreview(url: url, parsed: parsed)
    }

    /// Inserts the feed and its current items on the main context. Returns the new feed.
    @MainActor
    static func subscribe(_ preview: FeedPreview, lane: Lane, folder: Folder?, in context: ModelContext) throws -> Feed {
        let canonical = CanonicalURL.normalize(preview.url)
        let existing = try context.fetch(FetchDescriptor<Feed>(predicate: #Predicate { $0.canonicalURL == canonical }))
        if let existing = existing.first { throw SubscribeError.alreadySubscribed(existing.displayTitle) }

        let feed = Feed(url: preview.url.absoluteString, title: preview.parsed.title)
        feed.lane = lane
        feed.folder = folder
        feed.siteURL = preview.parsed.siteURL?.absoluteString
        feed.iconURL = preview.parsed.iconURL?.absoluteString ?? preview.parsed.siteURL.map { $0.appending(path: "favicon.ico").absoluteString }
        feed.hubURL = preview.parsed.hubURL?.absoluteString
        feed.format = preview.parsed.format
        feed.lastFetchedAt = Date()
        feed.lastSuccessAt = Date()
        context.insert(feed)

        var newest: Date?
        for entry in preview.parsed.items {
            let item = Item(guid: entry.guid, title: entry.title)
            item.url = entry.url?.absoluteString
            item.canonicalURL = entry.url.map(CanonicalURL.normalize)
            item.author = entry.author
            item.publishedAt = entry.published
            item.updatedAt = entry.updated
            item.summaryHTML = entry.summaryHTML
            item.contentHTML = entry.contentHTML
            item.contentText = entry.bestHTML.map(HTMLText.plainText) ?? ""
            item.imageURL = entry.imageURL?.absoluteString
            item.wordCount = HTMLText.wordCount(item.contentText)
            item.fingerprint = Fingerprint.make(entry.guid, entry.title, item.contentText)
            item.feed = feed
            context.insert(item)
            if let published = entry.published, published > (newest ?? .distantPast) { newest = published }
        }
        feed.lastPostedAt = newest
        let interval = FetchScheduler.interval(postDates: preview.parsed.items.compactMap(\.published), isPriority: lane == .priority, errorCount: 0)
        feed.fetchIntervalSeconds = Int(interval)
        feed.nextFetchAt = Date().addingTimeInterval(interval)
        try context.save()
        return feed
    }

    /// A short, good starting library for people who arrive with nothing. Every entry is a
    /// real, actively published feed as of September 2026.
    static let starterFeeds: [(title: String, url: String, lane: Lane, folder: String)] = [
        ("Daring Fireball", "https://daringfireball.net/feeds/main", .priority, "Priority"),
        ("MacStories", "https://www.macstories.net/feed/", .priority, "Priority"),
        ("Six Colors", "https://sixcolors.com/feed/", .normal, "Tech"),
        ("9to5Mac", "https://9to5mac.com/feed/", .normal, "Tech"),
        ("Dezeen", "https://www.dezeen.com/feed/", .normal, "Design"),
        ("Sidebar", "https://sidebar.io/feed.xml", .normal, "Design"),
        ("Craig Mod", "https://craigmod.com/index.xml", .normal, "Writing"),
        ("Hacker News", "https://news.ycombinator.com/rss", .ambient, "Ambient"),
    ]
}
