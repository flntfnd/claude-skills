import Foundation
import OSLog
import SwiftData
import SwiftUI
import TributaryCore
import UniformTypeIdentifiers

/// Builds the archive described in CONCEPT.md section 4 as a directory FileWrapper:
/// OPML for subscriptions, JSON Lines for per-item state, JSON Feed plus Markdown plus HTML
/// for every saved article, Markdown for highlights. Same format for manual export, the
/// iCloud Drive mirror, and mode switching.
enum ArchiveBuilder {
    static let formatVersion = 1

    @MainActor
    static func build(context: ModelContext, settings: AppSettings) throws -> FileWrapper {
        let feeds = try context.fetch(FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.title)]))
        let folders = try context.fetch(FetchDescriptor<Folder>(sortBy: [SortDescriptor(\.sortOrder)]))
        let items = try context.fetch(FetchDescriptor<Item>())
        let stacks = try context.fetch(FetchDescriptor<ItemStack>())
        let stateful = items.filter { $0.isRead || $0.isSaved || $0.readPosition > 0 || $0.snoozedUntil != nil || !$0.tags.isEmpty || $0.note != nil }
        let saved = items.filter(\.isSaved)
        let highlights = items.flatMap { item in (item.highlights ?? []).map { (item, $0) } }

        var root: [String: FileWrapper] = [:]

        root["manifest.json"] = file(try JSONEncoder.pretty.encode(Manifest(
            formatVersion: formatVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0",
            mode: settings.storageMode?.rawValue ?? "device",
            createdAt: Date(),
            counts: .init(feeds: feeds.count, folders: folders.count, items: stateful.count, saved: saved.count, highlights: highlights.count)
        )))

        root["subscriptions.opml"] = file(OPML.render(opml(feeds: feeds, folders: folders)))
        root["rules.json"] = file(Data("[]".utf8))
        root["settings.json"] = file(try JSONEncoder.pretty.encode(settings.exportable))

        var state: [String: FileWrapper] = [:]
        state["items.jsonl"] = file(Data(stateful.map(ItemStateLine.init).compactMap { line in
            (try? JSONEncoder.compact.encode(line)).flatMap { String(data: $0, encoding: .utf8) }
        }.joined(separator: "\n").utf8))
        state["queues.json"] = file(try JSONEncoder.pretty.encode(stacks.filter(\.isUpNext).map(StackLine.init)))
        state["stacks.json"] = file(try JSONEncoder.pretty.encode(stacks.filter { !$0.isUpNext }.map(StackLine.init)))
        root["state"] = FileWrapper(directoryWithFileWrappers: state)

        var savedDirectory: [String: FileWrapper] = [:]
        for (slug, group) in Dictionary(grouping: saved, by: { Slug.make($0.feed?.displayTitle ?? "saved-links") }) {
            var feedDirectory: [String: FileWrapper] = [:]
            feedDirectory["feed.json"] = file(try JSONEncoder.pretty.encode(jsonFeed(title: group.first?.feed?.displayTitle ?? "Saved links", items: group)))
            for item in group {
                let itemSlug = Slug.make(item.title, fallback: item.id.uuidString)
                feedDirectory[itemSlug + ".md"] = file(Data(Markdown.article(item).utf8))
                feedDirectory[itemSlug + ".html"] = file(Data(HTMLDocument.article(item).utf8))
            }
            savedDirectory[slug] = FileWrapper(directoryWithFileWrappers: feedDirectory)
        }
        root["saved"] = FileWrapper(directoryWithFileWrappers: savedDirectory)

        var highlightDirectory: [String: FileWrapper] = [:]
        highlightDirectory["highlights.json"] = file(try JSONEncoder.pretty.encode(highlights.map { HighlightLine(item: $0.0, highlight: $0.1) }))
        for (slug, group) in Dictionary(grouping: highlights, by: { Slug.make($0.0.feed?.displayTitle ?? "saved-links") }) {
            highlightDirectory[slug + ".md"] = file(Data(Markdown.highlights(group).utf8))
        }
        root["highlights"] = FileWrapper(directoryWithFileWrappers: highlightDirectory)

        let wrapper = FileWrapper(directoryWithFileWrappers: root)
        wrapper.preferredFilename = "Tributary Export " + ISO8601DateFormatter.dayOnly.string(from: Date())
        return wrapper
    }

    private static func file(_ data: Data) -> FileWrapper { FileWrapper(regularFileWithContents: data) }

    static func opml(feeds: [Feed], folders: [Folder]) -> OPMLDocument {
        func outline(_ feed: Feed) -> OPMLOutline {
            var attributes = ["tributary:lane": feed.lane.rawValue]
            if feed.isMuted { attributes["tributary:muted"] = "true" }
            if feed.dailyCap > 0 { attributes["tributary:cap"] = String(feed.dailyCap) }
            if let custom = feed.customTitle, !custom.isEmpty { attributes["tributary:customTitle"] = custom }
            return OPMLOutline(text: feed.displayTitle, title: feed.title, xmlURL: URL(string: feed.url), htmlURL: feed.siteURL.flatMap(URL.init(string:)), type: "rss", attributes: attributes)
        }
        var outlines: [OPMLOutline] = []
        for folder in folders {
            let members = feeds.filter { $0.folder?.id == folder.id }
            guard !members.isEmpty else { continue }
            outlines.append(OPMLOutline(text: folder.name, children: members.map(outline)))
        }
        outlines += feeds.filter { $0.folder == nil }.map(outline)
        return OPMLDocument(title: "Tributary subscriptions", dateCreated: Date(), outlines: outlines)
    }

    private static func jsonFeed(title: String, items: [Item]) -> JSONFeedOut {
        JSONFeedOut(title: title, items: items.map { item in
            JSONFeedOut.Entry(
                id: item.guid,
                url: item.url,
                title: item.title,
                content_html: item.contentHTML ?? item.summaryHTML,
                content_text: item.contentText,
                date_published: item.publishedAt.map(ISO8601DateFormatter.standard.string(from:)),
                authors: item.author.map { [.init(name: $0)] },
                tags: item.tags.isEmpty ? nil : item.tags,
                image: item.imageURL
            )
        })
    }

    // MARK: Encodable shapes

    struct Manifest: Encodable {
        struct Counts: Encodable { var feeds: Int; var folders: Int; var items: Int; var saved: Int; var highlights: Int }
        var formatVersion: Int
        var appVersion: String
        var mode: String
        var createdAt: Date
        var counts: Counts
    }

    struct ItemStateLine: Codable {
        var feed_url: String?
        var guid: String
        var url: String?
        var read: Bool
        var saved: Bool
        var read_position: Double
        var snoozed_until: Date?
        var tags: [String]
        var note: String?
        var updated_at: Date

        init(_ item: Item) {
            feed_url = item.feed?.url
            guid = item.guid
            url = item.url
            read = item.isRead
            saved = item.isSaved
            read_position = item.readPosition
            snoozed_until = item.snoozedUntil
            tags = item.tags
            note = item.note
            updated_at = item.readAt ?? item.savedAt ?? item.receivedAt
        }
    }

    struct StackLine: Codable {
        var id: UUID
        var name: String?
        var created_at: Date
        var item_ids: [UUID]
        init(_ stack: ItemStack) { id = stack.id; name = stack.name; created_at = stack.createdAt; item_ids = stack.itemIDs }
    }

    struct HighlightLine: Encodable {
        var feed_url: String?
        var guid: String
        var quote: String
        var note: String?
        var position: Double
        var created_at: Date
        init(item: Item, highlight: Highlight) {
            feed_url = item.feed?.url; guid = item.guid; quote = highlight.quote; note = highlight.note; position = highlight.position; created_at = highlight.createdAt
        }
    }

    struct JSONFeedOut: Encodable {
        struct Author: Encodable { var name: String }
        struct Entry: Encodable {
            var id: String; var url: String?; var title: String; var content_html: String?; var content_text: String?
            var date_published: String?; var authors: [Author]?; var tags: [String]?; var image: String?
        }
        var version = "https://jsonfeed.org/version/1.1"
        var title: String
        var items: [Entry]
    }
}

/// Markdown with YAML front matter, so the saved folder opens as an Obsidian vault.
enum Markdown {
    static func article(_ item: Item) -> String {
        var lines = ["---"]
        lines.append("title: \"\(item.title.replacingOccurrences(of: "\"", with: "\\\""))\"")
        if let url = item.url { lines.append("url: \(url)") }
        if let feed = item.feed { lines.append("feed: \"\(feed.displayTitle)\"") }
        if let author = item.author { lines.append("author: \"\(author)\"") }
        if let published = item.publishedAt { lines.append("published: \(ISO8601DateFormatter.standard.string(from: published))") }
        if let saved = item.savedAt { lines.append("saved_at: \(ISO8601DateFormatter.standard.string(from: saved))") }
        if !item.tags.isEmpty { lines.append("tags: [\(item.tags.joined(separator: ", "))]") }
        lines.append("---")
        lines.append("")
        lines.append("# " + item.title)
        lines.append("")
        let blocks = item.extractedBlocks ?? item.bodyHTML.map { HTMLBlocks.blocks(from: $0, baseURL: item.link) } ?? []
        for block in blocks {
            lines.append(render(block))
            lines.append("")
        }
        if let highlights = item.highlights, !highlights.isEmpty {
            lines.append("## Highlights")
            lines.append("")
            for highlight in highlights.sorted(by: { $0.position < $1.position }) {
                lines.append("> " + highlight.quote.replacingOccurrences(of: "\n", with: "\n> "))
                if let note = highlight.note, !note.isEmpty { lines.append("\n" + note) }
                lines.append("")
            }
        }
        if let note = item.note, !note.isEmpty {
            lines.append("## Note")
            lines.append("")
            lines.append(note)
        }
        return lines.joined(separator: "\n")
    }

    static func highlights(_ pairs: [(Item, Highlight)]) -> String {
        var lines: [String] = []
        let byItem = Dictionary(grouping: pairs, by: { $0.0.id })
        let groups: [(Item, [Highlight])] = byItem.values.map { ($0[0].0, $0.map { $0.1 }) }
        for (item, group) in groups.sorted(by: { $0.0.title < $1.0.title }) {
            lines.append("# " + item.title)
            if let url = item.url { lines.append(url) }
            lines.append("")
            for highlight in group.sorted(by: { $0.position < $1.position }) {
                lines.append("> " + highlight.quote)
                if let note = highlight.note, !note.isEmpty { lines.append("\n" + note) }
                lines.append("")
            }
        }
        return lines.joined(separator: "\n")
    }

    static func render(_ block: ContentBlock) -> String {
        switch block {
        case let .heading(level, text): String(repeating: "#", count: min(6, level + 1)) + " " + inline(text)
        case let .paragraph(text): inline(text)
        case let .quote(text): "> " + inline(text)
        case let .image(url, alt, caption): "![\(alt ?? "")](\(url.absoluteString))" + (caption.map { "\n\n*\($0)*" } ?? "")
        case let .code(code): "```\n\(code)\n```"
        case let .list(ordered, items): items.enumerated().map { ordered ? "\($0.offset + 1). \(inline($0.element))" : "- \(inline($0.element))" }.joined(separator: "\n")
        case .rule: "---"
        }
    }

    static func inline(_ text: InlineText) -> String {
        text.runs.map { run in
            var value = run.text
            if run.isCode { value = "`\(value)`" }
            if run.isBold { value = "**\(value)**" }
            if run.isItalic { value = "*\(value)*" }
            if let link = run.link { value = "[\(value)](\(link.absoluteString))" }
            return value
        }.joined()
    }
}

/// A self-contained page for each saved article, so it opens in any browser without the app.
enum HTMLDocument {
    static func article(_ item: Item) -> String {
        let body = item.extractedBlocks.map { blocks in blocks.map(render).joined(separator: "\n") } ?? item.bodyHTML ?? ""
        return """
        <!doctype html>
        <html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
        <title>\(HTMLText.escape(item.title))</title>
        <style>body{max-width:40rem;margin:3rem auto;padding:0 1.25rem;font:19px/1.6 -apple-system,system-ui,sans-serif;color:#1b1b19;background:#f7f6f2}img{max-width:100%;height:auto}blockquote{border-left:3px solid #e5631d;margin:0;padding-left:1rem;color:#5b5952}pre{overflow:auto;background:#f0eee8;padding:1rem;border-radius:8px}figcaption,.meta{color:#7d7a72;font-size:.85em}</style>
        </head><body>
        <p class="meta">\(HTMLText.escape(item.sourceTitle))\(item.author.map { " · " + HTMLText.escape($0) } ?? "")\(item.publishedAt.map { " · " + $0.formatted(date: .long, time: .omitted) } ?? "")</p>
        <h1>\(HTMLText.escape(item.title))</h1>
        \(item.url.map { "<p class=\"meta\"><a href=\"\($0)\">\($0)</a></p>" } ?? "")
        \(body)
        </body></html>
        """
    }

    static func render(_ block: ContentBlock) -> String {
        switch block {
        case let .heading(level, text): "<h\(min(6, level + 1))>\(inline(text))</h\(min(6, level + 1))>"
        case let .paragraph(text): "<p>\(inline(text))</p>"
        case let .quote(text): "<blockquote><p>\(inline(text))</p></blockquote>"
        case let .image(url, alt, caption): "<figure><img src=\"\(url.absoluteString)\" alt=\"\(HTMLText.escape(alt ?? ""))\">\(caption.map { "<figcaption>\(HTMLText.escape($0))</figcaption>" } ?? "")</figure>"
        case let .code(code): "<pre><code>\(HTMLText.escape(code))</code></pre>"
        case let .list(ordered, items): (ordered ? "<ol>" : "<ul>") + items.map { "<li>\(inline($0))</li>" }.joined() + (ordered ? "</ol>" : "</ul>")
        case .rule: "<hr>"
        }
    }

    static func inline(_ text: InlineText) -> String {
        text.runs.map { run in
            var value = HTMLText.escape(run.text)
            if run.isCode { value = "<code>\(value)</code>" }
            if run.isBold { value = "<strong>\(value)</strong>" }
            if run.isItalic { value = "<em>\(value)</em>" }
            if let link = run.link { value = "<a href=\"\(link.absoluteString)\">\(value)</a>" }
            return value
        }.joined()
    }
}

/// Keeps a Tributary folder in iCloud Drive current with the archive. Written after refreshes
/// that brought new items and after any save or highlight, debounced so a burst of changes is
/// one write. Never read back by the app.
actor ArchiveMirror {
    static let shared = ArchiveMirror()
    private var pending: Task<Void, Never>?
    private let logger = Logger(subsystem: "com.flntfnd.tributary", category: "mirror")

    func scheduleWrite(container: ModelContainer) {
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled else { return }
            await write(container: container)
        }
    }

    func write(container: ModelContainer) async {
        guard let base = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            logger.info("iCloud Drive is not available; mirror skipped")
            return
        }
        let wrapper: FileWrapper
        do {
            wrapper = try await MainActor.run {
                try ArchiveBuilder.build(context: container.mainContext, settings: AppSettings.shared)
            }
        } catch {
            logger.error("Archive build failed: \(error.localizedDescription, privacy: .public)")
            return
        }
        let target = base.appending(path: "Documents/Tributary", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            try wrapper.write(to: target, options: .atomic, originalContentsURL: nil)
            await MainActor.run { AppSettings.shared.lastArchiveMirrorAt = Date() }
        } catch {
            logger.error("Mirror write failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

/// `.fileExporter` needs a document; this wraps the archive directory.
struct ArchiveDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.folder]
    static let writableContentTypes: [UTType] = [.folder]
    let wrapper: FileWrapper

    init(wrapper: FileWrapper) { self.wrapper = wrapper }
    init(configuration: ReadConfiguration) throws { wrapper = configuration.file }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { wrapper }
}

enum Slug {
    static func make(_ text: String, fallback: String = "untitled") -> String {
        let lowered = text.lowercased().folding(options: .diacriticInsensitive, locale: nil)
        var slug = ""
        var lastDash = true
        for scalar in lowered.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                slug.unicodeScalars.append(scalar)
                lastDash = false
            } else if !lastDash {
                slug.append("-")
                lastDash = true
            }
            if slug.count >= 72 { break }
        }
        while slug.hasSuffix("-") { slug.removeLast() }
        return slug.isEmpty ? fallback : slug
    }
}

extension JSONEncoder {
    nonisolated(unsafe) static let pretty: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    nonisolated(unsafe) static let compact: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension ISO8601DateFormatter {
    nonisolated(unsafe) static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    nonisolated(unsafe) static let dayOnly: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}
