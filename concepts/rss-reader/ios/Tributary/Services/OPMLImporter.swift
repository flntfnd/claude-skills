import Foundation
import SwiftData
import TributaryCore

/// Import previews before it commits, dedupes by canonical URL, and never un-reads anything.
/// OPML only carries subscriptions; a full Tributary archive import adds state on top.
enum OPMLImporter {
    struct Preview: Sendable {
        var document: OPMLDocument
        var newFeeds: Int
        var skippedFeeds: Int
        var folders: Int
    }

    @MainActor
    static func preview(data: Data, context: ModelContext) throws -> Preview {
        let document = try OPML.parse(data: data)
        let existing = Set(try context.fetch(FetchDescriptor<Feed>()).map(\.canonicalURL))
        var new = 0, skipped = 0
        var folders = Set<String>()
        for entry in document.feeds {
            guard let url = entry.outline.xmlURL else { continue }
            if existing.contains(CanonicalURL.normalize(url)) { skipped += 1 } else { new += 1 }
            if let first = entry.folderPath.first { folders.insert(first) }
        }
        return Preview(document: document, newFeeds: new, skippedFeeds: skipped, folders: folders.count)
    }

    /// Inserts feeds and folders. Items arrive with the next refresh. Returns the new feed IDs.
    @MainActor
    static func commit(_ preview: Preview, context: ModelContext) throws -> [UUID] {
        let existingFeeds = try context.fetch(FetchDescriptor<Feed>())
        var known = Set(existingFeeds.map(\.canonicalURL))
        var folders = Dictionary(try context.fetch(FetchDescriptor<Folder>()).map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        var order = existingFeeds.count
        var created: [UUID] = []

        for entry in preview.document.feeds {
            guard let url = entry.outline.xmlURL else { continue }
            let canonical = CanonicalURL.normalize(url)
            guard known.insert(canonical).inserted else { continue }
            let feed = Feed(url: url.absoluteString, title: entry.outline.title ?? entry.outline.text)
            feed.siteURL = entry.outline.htmlURL?.absoluteString
            feed.sortOrder = order
            order += 1
            if let lane = entry.outline.attributes["tributary:lane"].flatMap(Lane.init(rawValue:)) { feed.lane = lane }
            if entry.outline.attributes["tributary:muted"] == "true" { feed.isMuted = true }
            if let cap = entry.outline.attributes["tributary:cap"].flatMap(Int.init) { feed.dailyCap = cap }
            if let custom = entry.outline.attributes["tributary:customTitle"], !custom.isEmpty { feed.customTitle = custom }
            if let folderName = entry.folderPath.first {
                if let folder = folders[folderName] {
                    feed.folder = folder
                } else {
                    let folder = Folder(name: folderName, sortOrder: folders.count)
                    context.insert(folder)
                    folders[folderName] = folder
                    feed.folder = folder
                }
                if feed.laneRaw == Lane.normal.rawValue, folderName.lowercased() == "priority" { feed.lane = .priority }
                if feed.laneRaw == Lane.normal.rawValue, folderName.lowercased() == "ambient" { feed.lane = .ambient }
            }
            context.insert(feed)
            created.append(feed.id)
        }
        try context.save()
        return created
    }
}
