import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

/// Entry point for turning bytes into a `ParsedFeed`. Sniffs JSON Feed by the first
/// non-whitespace byte and hands everything else to the XML parser, which handles
/// RSS 2.0, RSS 1.0 (RDF), and Atom in one pass.
public enum FeedParser {
    public static func parse(data: Data, sourceURL: URL? = nil) throws -> ParsedFeed {
        guard let first = data.first(where: { !($0 == 0x20 || $0 == 0x09 || $0 == 0x0A || $0 == 0x0D) }) else {
            throw FeedParserError.empty
        }
        if first == UInt8(ascii: "{") {
            return try JSONFeedParser.parse(data: data, sourceURL: sourceURL)
        }
        return try XMLFeedParser.parse(data: data, sourceURL: sourceURL)
    }
}

// MARK: - XML (RSS 2.0, RDF, Atom)

enum XMLFeedParser {
    static func parse(data: Data, sourceURL: URL?) throws -> ParsedFeed {
        let delegate = XMLFeedDelegate(sourceURL: sourceURL)
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate
        let ok = parser.parse()
        if let error = delegate.fatal {
            throw FeedParserError.malformed(error)
        }
        guard ok || !delegate.items.isEmpty else {
            let message = parser.parserError?.localizedDescription ?? "unknown XML error"
            throw FeedParserError.malformed(message)
        }
        guard let format = delegate.format else { throw FeedParserError.unrecognizedFormat }
        return ParsedFeed(
            title: delegate.feedTitle.trimmed,
            siteURL: delegate.siteURL,
            feedDescription: delegate.feedDescription?.trimmed,
            iconURL: delegate.iconURL,
            hubURL: delegate.hubURL,
            format: format,
            items: delegate.items
        )
    }
}

private final class XMLFeedDelegate: NSObject, XMLParserDelegate {
    private struct ItemBuilder {
        var guid: String?
        var guidIsPermalink = true
        var url: URL?
        var title = ""
        var author: String?
        var published: Date?
        var updated: Date?
        var summaryHTML: String?
        var contentHTML: String?
        var imageURL: URL?
        var enclosures: [Enclosure] = []
        var categories: [String] = []
    }

    let sourceURL: URL?
    private(set) var format: FeedFormat?
    private(set) var feedTitle = ""
    private(set) var feedDescription: String?
    private(set) var siteURL: URL?
    private(set) var iconURL: URL?
    private(set) var hubURL: URL?
    private(set) var items: [ParsedItem] = []
    private(set) var fatal: String?

    private var path: [String] = []
    private var text = ""
    private var current: ItemBuilder?
    private var inAuthor = false
    private var inImage = false
    private let dates = FeedDates()

    init(sourceURL: URL?) {
        self.sourceURL = sourceURL
    }

    private var inItem: Bool { current != nil }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        let local = elementName.lowercased()
        let qualified = (qName ?? elementName).lowercased()
        path.append(local)
        text = ""

        if format == nil {
            switch local {
            case "rss": format = .rss
            case "rdf": format = .rss
            case "feed": format = .atom
            default: break
            }
        }

        switch local {
        case "item", "entry":
            current = ItemBuilder()
        case "author":
            inAuthor = true
        case "image":
            inImage = !inItem
        case "link":
            if let href = attributeDict["href"] {
                handleAtomLink(href: href, rel: attributeDict["rel"] ?? "alternate", type: attributeDict["type"])
            }
        case "enclosure":
            if inItem, let urlString = attributeDict["url"], let url = resolve(urlString) {
                let length = attributeDict["length"].flatMap { Int($0) }
                current?.enclosures.append(Enclosure(url: url, mimeType: attributeDict["type"], length: length))
            }
        case "content", "thumbnail":
            // media:content and media:thumbnail carry the image in a url attribute; Atom <content> does not.
            if inItem, qualified.hasPrefix("media:"), let urlString = attributeDict["url"], let url = resolve(urlString) {
                let type = attributeDict["type"] ?? ""
                let medium = attributeDict["medium"] ?? ""
                if local == "thumbnail" || type.hasPrefix("image/") || medium == "image" {
                    if current?.imageURL == nil { current?.imageURL = url }
                }
            }
        case "category":
            if inItem, let term = attributeDict["term"], !term.isEmpty {
                current?.categories.append(term)
            }
        case "guid":
            if let permalink = attributeDict["isPermaLink"]?.lowercased() {
                current?.guidIsPermalink = permalink != "false"
            }
        case "icon", "logo":
            break
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        text += String(decoding: CDATABlock, as: UTF8.self)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let local = elementName.lowercased()
        let qualified = (qName ?? elementName).lowercased()
        let value = text
        text = ""
        defer { _ = path.popLast() }

        switch (local, qualified) {
        case ("item", _), ("entry", _):
            if let builder = current { items.append(finish(builder)) }
            current = nil
            return
        case ("author", _):
            inAuthor = false
            if inItem, format != .atom, !value.trimmed.isEmpty {
                current?.author = value.trimmed
            }
            return
        case ("image", _):
            inImage = false
            return
        default:
            break
        }

        if inItem {
            endItemElement(local: local, qualified: qualified, value: value)
        } else {
            endFeedElement(local: local, qualified: qualified, value: value)
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        // Recoverable errors (bad entity, stray ampersand) are common in the wild. Only treat
        // the document as unusable when nothing parsed at all.
        if items.isEmpty && format == nil {
            fatal = parseError.localizedDescription
        }
    }

    private func endItemElement(local: String, qualified: String, value: String) {
        let trimmed = value.trimmed
        switch (local, qualified) {
        case ("title", _):
            current?.title = HTMLText.plainText(trimmed)
        case ("link", _):
            if !trimmed.isEmpty, let url = resolve(trimmed) { current?.url = url }
        case ("guid", _), ("id", _):
            if !trimmed.isEmpty { current?.guid = trimmed }
        case ("pubdate", _), ("published", _), ("issued", _), (_, "dc:date"):
            current?.published = dates.parse(trimmed)
        case ("updated", _), ("modified", _):
            current?.updated = dates.parse(trimmed)
        case ("description", _):
            if !trimmed.isEmpty { current?.summaryHTML = trimmed }
        case ("encoded", "content:encoded"):
            if !trimmed.isEmpty { current?.contentHTML = trimmed }
        case ("content", _):
            if !trimmed.isEmpty, !qualified.hasPrefix("media:") { current?.contentHTML = trimmed }
        case ("summary", _):
            if !trimmed.isEmpty { current?.summaryHTML = trimmed }
        case ("creator", "dc:creator"):
            if !trimmed.isEmpty { current?.author = trimmed }
        case ("name", _):
            if inAuthor, !trimmed.isEmpty { current?.author = trimmed }
        case ("category", _):
            if !trimmed.isEmpty, format != .atom { current?.categories.append(trimmed) }
        default:
            break
        }
    }

    private func endFeedElement(local: String, qualified: String, value: String) {
        let trimmed = value.trimmed
        switch (local, qualified) {
        case ("title", _):
            if inImage { return }
            if feedTitle.isEmpty, path.count <= 3 { feedTitle = HTMLText.plainText(trimmed) }
        case ("link", _):
            if !trimmed.isEmpty, siteURL == nil, !inImage, let url = resolve(trimmed) { siteURL = url }
        case ("description", _), ("subtitle", _):
            if feedDescription == nil, !trimmed.isEmpty { feedDescription = HTMLText.plainText(trimmed) }
        case ("url", _):
            if inImage, iconURL == nil, let url = resolve(trimmed) { iconURL = url }
        case ("icon", _), ("logo", _):
            if iconURL == nil, let url = resolve(trimmed) { iconURL = url }
        default:
            break
        }
    }

    private func handleAtomLink(href: String, rel: String, type: String?) {
        guard let url = resolve(href) else { return }
        if inItem {
            switch rel {
            case "alternate":
                if current?.url == nil { current?.url = url }
            case "enclosure":
                current?.enclosures.append(Enclosure(url: url, mimeType: type, length: nil))
                if type?.hasPrefix("image/") == true, current?.imageURL == nil { current?.imageURL = url }
            default:
                break
            }
        } else {
            switch rel {
            case "alternate":
                if siteURL == nil { siteURL = url }
            case "hub":
                hubURL = url
            default:
                break
            }
        }
    }

    private func finish(_ builder: ItemBuilder) -> ParsedItem {
        var url = builder.url
        if url == nil, let guid = builder.guid, builder.guidIsPermalink, guid.hasPrefix("http"), let permalink = URL(string: guid) {
            url = permalink
        }
        let guid = builder.guid
            ?? url?.absoluteString
            ?? Fingerprint.make(builder.title, dates.iso(builder.published))
        var image = builder.imageURL
        if image == nil, let html = builder.contentHTML ?? builder.summaryHTML {
            image = HTMLText.firstImageURL(in: html, base: url ?? siteURL)
        }
        if image == nil, let enclosure = builder.enclosures.first(where: \.isImage) {
            image = enclosure.url
        }
        return ParsedItem(
            guid: guid,
            url: url,
            title: builder.title.isEmpty ? (url?.host ?? "Untitled") : builder.title,
            author: builder.author,
            published: builder.published ?? builder.updated,
            updated: builder.updated,
            summaryHTML: builder.summaryHTML,
            contentHTML: builder.contentHTML,
            imageURL: image,
            enclosures: builder.enclosures,
            categories: builder.categories
        )
    }

    private func resolve(_ string: String) -> URL? {
        let cleaned = string.trimmed
        guard !cleaned.isEmpty else { return nil }
        if let base = siteURL ?? sourceURL, let url = URL(string: cleaned, relativeTo: base) {
            return url.absoluteURL
        }
        return URL(string: cleaned)
    }
}

// MARK: - JSON Feed 1.1

enum JSONFeedParser {
    private struct Document: Decodable {
        struct Hub: Decodable { var type: String?; var url: String? }
        struct Author: Decodable { var name: String? }
        struct Attachment: Decodable {
            var url: String
            var mime_type: String?
            var size_in_bytes: Int?
        }
        struct Item: Decodable {
            var id: FlexibleString
            var url: String?
            var external_url: String?
            var title: String?
            var content_html: String?
            var content_text: String?
            var summary: String?
            var image: String?
            var banner_image: String?
            var date_published: String?
            var date_modified: String?
            var authors: [Author]?
            var author: Author?
            var tags: [String]?
            var attachments: [Attachment]?
        }
        var version: String?
        var title: String
        var home_page_url: String?
        var description: String?
        var icon: String?
        var favicon: String?
        var hubs: [Hub]?
        var items: [Item]
    }

    /// JSON Feed allows `id` to be a string or a number.
    struct FlexibleString: Decodable {
        let value: String
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                value = string
            } else if let int = try? container.decode(Int.self) {
                value = String(int)
            } else if let double = try? container.decode(Double.self) {
                value = String(double)
            } else {
                throw DecodingError.typeMismatch(String.self, .init(codingPath: decoder.codingPath, debugDescription: "id must be a string or number"))
            }
        }
    }

    static func parse(data: Data, sourceURL: URL?) throws -> ParsedFeed {
        let document: Document
        do {
            document = try JSONDecoder().decode(Document.self, from: data)
        } catch {
            throw FeedParserError.malformed("JSON Feed: \(error)")
        }
        let dates = FeedDates()
        let site = document.home_page_url.flatMap(URL.init(string:))
        let items = document.items.map { entry -> ParsedItem in
            let url = (entry.url ?? entry.external_url).flatMap(URL.init(string:))
            let html = entry.content_html ?? entry.content_text.map { HTMLText.escapedParagraphs($0) }
            let author = entry.authors?.first?.name ?? entry.author?.name
            let enclosures = (entry.attachments ?? []).compactMap { attachment -> Enclosure? in
                guard let url = URL(string: attachment.url) else { return nil }
                return Enclosure(url: url, mimeType: attachment.mime_type, length: attachment.size_in_bytes)
            }
            let image = (entry.image ?? entry.banner_image).flatMap(URL.init(string:))
                ?? html.flatMap { HTMLText.firstImageURL(in: $0, base: url ?? site) }
            return ParsedItem(
                guid: entry.id.value,
                url: url,
                title: entry.title ?? url?.host ?? "Untitled",
                author: author,
                published: entry.date_published.flatMap(dates.parse) ?? entry.date_modified.flatMap(dates.parse),
                updated: entry.date_modified.flatMap(dates.parse),
                summaryHTML: entry.summary,
                contentHTML: html,
                imageURL: image,
                enclosures: enclosures,
                categories: entry.tags ?? []
            )
        }
        return ParsedFeed(
            title: document.title,
            siteURL: site,
            feedDescription: document.description,
            iconURL: (document.icon ?? document.favicon).flatMap(URL.init(string:)),
            hubURL: document.hubs?.first?.url.flatMap(URL.init(string:)),
            format: .jsonFeed,
            items: items
        )
    }
}

// MARK: - Dates

/// RSS uses RFC 822, Atom and JSON Feed use RFC 3339, and real feeds use everything in between.
/// Formatters are not Sendable, so each parse creates its own set and keeps it for the document.
final class FeedDates {
    private let iso: ISO8601DateFormatter
    private let isoFractional: ISO8601DateFormatter
    private let fallbacks: [DateFormatter]

    init() {
        iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let patterns = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "EEE, d MMM yyyy HH:mm:ss Z",
            "dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm Z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
        ]
        fallbacks = patterns.map { pattern in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = pattern
            return formatter
        }
    }

    func parse(_ raw: String) -> Date? {
        let value = raw.trimmed
        guard !value.isEmpty else { return nil }
        if let date = isoFractional.date(from: value) ?? iso.date(from: value) { return date }
        for formatter in fallbacks {
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }

    func iso(_ date: Date?) -> String {
        guard let date else { return "" }
        return iso.string(from: date)
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
