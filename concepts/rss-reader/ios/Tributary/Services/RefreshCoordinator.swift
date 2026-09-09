import Foundation
import Observation
import OSLog
import SwiftData
import TributaryCore

enum RefreshReason: Sendable {
    case userPull
    case launch
    case background
    case subscription
}

struct RefreshReport: Sendable {
    var fetched = 0
    var notModified = 0
    var failed = 0
    var newItems = 0
    var errors: [String: String] = [:]
}

/// Main-actor facade the views talk to. The heavy lifting happens in `RefreshActor`, a
/// `ModelActor` with its own context, so the UI never blocks on parsing or inserting.
@MainActor
@Observable
final class RefreshCoordinator {
    private(set) var isRefreshing = false
    private(set) var lastReport: RefreshReport?
    private(set) var lastError: String?
    private let actor: RefreshActor
    private let logger = Logger(subsystem: "com.flntfnd.tributary", category: "refresh")

    init(container: ModelContainer) {
        actor = RefreshActor(modelContainer: container)
    }

    func refreshAll(reason: RefreshReason, force: Bool = false) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        let report = await actor.refreshAll(force: force || reason == .userPull)
        lastReport = report
        lastError = report.errors.isEmpty ? nil : "Couldn’t refresh \(report.errors.count) feed\(report.errors.count == 1 ? "" : "s")"
        AppSettings.shared.lastRefreshAt = Date()
        logger.info("Refresh (\(String(describing: reason), privacy: .public)): \(report.fetched) fetched, \(report.newItems) new, \(report.failed) failed")
        if AppSettings.shared.archiveMirrorEnabled, report.newItems > 0 {
            await ArchiveMirror.shared.scheduleWrite(container: actor.modelContainer)
        }
    }

    func refresh(feedID: UUID) async {
        _ = await actor.refresh(feedIDs: [feedID])
    }

    /// Fetches a page and stores the extracted article on the item. Used by the reader for
    /// truncated feeds and by Save Link.
    func extract(itemID: UUID) async -> Bool {
        await actor.extract(itemID: itemID)
    }
}

/// All writes from network results go through this actor's context. Fetching itself is
/// nonisolated and runs concurrently with a small parallelism cap; only the apply step is serial.
@ModelActor
actor RefreshActor {
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 25
        configuration.httpAdditionalHeaders = ["User-Agent": FeedFetcher.userAgent]
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()

    func refreshAll(force: Bool) async -> RefreshReport {
        let now = Date()
        let descriptor = FetchDescriptor<Feed>(predicate: #Predicate { !$0.isMuted })
        guard let feeds = try? modelContext.fetch(descriptor) else { return RefreshReport() }
        let due = feeds.filter { force || ($0.nextFetchAt ?? .distantPast) <= now }
        return await refresh(feeds: due)
    }

    func refresh(feedIDs: [UUID]) async -> RefreshReport {
        let descriptor = FetchDescriptor<Feed>(predicate: #Predicate { feedIDs.contains($0.id) })
        guard let feeds = try? modelContext.fetch(descriptor) else { return RefreshReport() }
        return await refresh(feeds: feeds)
    }

    private func refresh(feeds: [Feed]) async -> RefreshReport {
        var report = RefreshReport()
        guard !feeds.isEmpty else { return report }

        let jobs = feeds.map { FeedFetcher.Job(feedID: $0.id, url: $0.url, etag: $0.etag, lastModified: $0.lastModified) }
        let results = await FeedFetcher.fetchAll(jobs, session: session, concurrency: 6)

        for feed in feeds {
            guard let result = results[feed.id] else { continue }
            feed.lastFetchedAt = Date()
            switch result {
            case .notModified:
                report.notModified += 1
                feed.errorCount = 0
                feed.lastError = nil
                feed.lastSuccessAt = Date()
            case let .failed(message):
                report.failed += 1
                feed.errorCount += 1
                feed.lastError = message
                report.errors[feed.id.uuidString] = message
            case let .fetched(parsed, etag, lastModified):
                report.fetched += 1
                feed.errorCount = 0
                feed.lastError = nil
                feed.lastSuccessAt = Date()
                feed.etag = etag
                feed.lastModified = lastModified
                report.newItems += apply(parsed, to: feed)
            }
            let dates = (feed.items ?? []).compactMap(\.publishedAt)
            let interval = FetchScheduler.interval(postDates: dates, isPriority: feed.lane == .priority, errorCount: feed.errorCount)
            feed.fetchIntervalSeconds = Int(interval)
            feed.nextFetchAt = FetchScheduler.nextFetch(after: feed.lastFetchedAt, interval: interval)
        }
        try? modelContext.save()
        return report
    }

    /// Upserts parsed items into the feed. Returns how many were new.
    @discardableResult
    func apply(_ parsed: ParsedFeed, to feed: Feed) -> Int {
        if feed.title.isEmpty || feed.title == feed.url { feed.title = parsed.title }
        if feed.siteURL == nil { feed.siteURL = parsed.siteURL?.absoluteString }
        if feed.iconURL == nil {
            feed.iconURL = parsed.iconURL?.absoluteString ?? parsed.siteURL.map { $0.appending(path: "favicon.ico").absoluteString }
        }
        feed.hubURL = parsed.hubURL?.absoluteString
        feed.format = parsed.format

        let existing = Dictionary((feed.items ?? []).map { ($0.guid, $0) }, uniquingKeysWith: { first, _ in first })
        var inserted = 0
        var newest = feed.lastPostedAt

        for entry in parsed.items {
            if let current = existing[entry.guid] {
                update(current, from: entry)
            } else if let current = entry.url.flatMap({ url in existingByCanonical(feed: feed, canonical: CanonicalURL.normalize(url)) }) {
                update(current, from: entry)
            } else {
                let item = Item(guid: entry.guid, title: entry.title)
                fill(item, from: entry)
                item.feed = feed
                modelContext.insert(item)
                inserted += 1
            }
            if let published = entry.published, published > (newest ?? .distantPast) { newest = published }
        }
        feed.lastPostedAt = newest
        return inserted
    }

    private func existingByCanonical(feed: Feed, canonical: String) -> Item? {
        (feed.items ?? []).first { $0.canonicalURL == canonical }
    }

    private func fill(_ item: Item, from entry: ParsedItem) {
        item.url = entry.url?.absoluteString
        item.canonicalURL = entry.url.map(CanonicalURL.normalize)
        item.title = entry.title
        item.author = entry.author
        item.publishedAt = entry.published
        item.updatedAt = entry.updated
        item.summaryHTML = entry.summaryHTML
        item.contentHTML = entry.contentHTML
        item.contentText = entry.bestHTML.map(HTMLText.plainText) ?? ""
        item.imageURL = entry.imageURL?.absoluteString
        item.wordCount = HTMLText.wordCount(item.contentText)
        item.fingerprint = Fingerprint.make(entry.guid, entry.title, item.contentText)
    }

    /// Feeds re-deliver corrected posts constantly. Keep the read state, count the change so the
    /// reader can show an "updated" chip instead of silently marking it unread again.
    private func update(_ item: Item, from entry: ParsedItem) {
        let text = entry.bestHTML.map(HTMLText.plainText) ?? ""
        let fingerprint = Fingerprint.make(entry.guid, entry.title, text)
        guard fingerprint != item.fingerprint else { return }
        if item.isRead { item.updateCount += 1 }
        item.title = entry.title
        item.author = entry.author ?? item.author
        item.updatedAt = entry.updated ?? Date()
        item.summaryHTML = entry.summaryHTML
        item.contentHTML = entry.contentHTML
        item.contentText = text
        item.wordCount = HTMLText.wordCount(text)
        item.imageURL = entry.imageURL?.absoluteString ?? item.imageURL
        item.fingerprint = fingerprint
        item.extractedBlocksData = nil
    }

    func extract(itemID: UUID) async -> Bool {
        let descriptor = FetchDescriptor<Item>(predicate: #Predicate { $0.id == itemID })
        guard let item = try? modelContext.fetch(descriptor).first, let url = item.link else { return false }
        guard let html = try? await FeedFetcher.fetchPage(url, session: session) else { return false }
        let article = ArticleExtractor.extract(html: html, baseURL: url)
        guard !article.blocks.isEmpty else { return false }
        item.extractedBlocks = article.blocks
        let text = article.plainText
        if text.count > item.contentText.count {
            item.contentText = text
            item.wordCount = article.wordCount
        }
        if item.imageURL == nil { item.imageURL = article.leadImageURL?.absoluteString }
        if item.title.isEmpty, let title = article.title { item.title = title }
        if item.author == nil { item.author = article.author }
        try? modelContext.save()
        return true
    }
}
