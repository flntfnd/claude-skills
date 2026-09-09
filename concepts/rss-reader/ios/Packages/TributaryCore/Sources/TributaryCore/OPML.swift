import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

/// One `<outline>` element. Folders are outlines with children and no `xmlUrl`.
public struct OPMLOutline: Sendable, Hashable, Codable {
    public var text: String
    public var title: String?
    public var xmlURL: URL?
    public var htmlURL: URL?
    public var type: String?
    /// Everything else on the element, including the `tributary:` namespace (lane, muted, cap).
    public var attributes: [String: String]
    public var children: [OPMLOutline]

    public init(text: String, title: String? = nil, xmlURL: URL? = nil, htmlURL: URL? = nil, type: String? = nil, attributes: [String: String] = [:], children: [OPMLOutline] = []) {
        self.text = text
        self.title = title
        self.xmlURL = xmlURL
        self.htmlURL = htmlURL
        self.type = type
        self.attributes = attributes
        self.children = children
    }

    public var isFeed: Bool { xmlURL != nil }

    /// Depth-first list of every feed outline, with the folder path it sits under.
    public func flattened(path: [String] = []) -> [(folderPath: [String], outline: OPMLOutline)] {
        if isFeed { return [(path, self)] }
        return children.flatMap { $0.flattened(path: path + [text]) }
    }
}

public struct OPMLDocument: Sendable, Hashable {
    public var title: String
    public var dateCreated: Date?
    public var outlines: [OPMLOutline]

    public init(title: String, dateCreated: Date? = nil, outlines: [OPMLOutline]) {
        self.title = title
        self.dateCreated = dateCreated
        self.outlines = outlines
    }

    public var feeds: [(folderPath: [String], outline: OPMLOutline)] {
        outlines.flatMap { $0.flattened() }
    }
}

public enum OPML {
    public static let namespace = "https://tributary.app/opml"

    public static func parse(data: Data) throws -> OPMLDocument {
        let delegate = OPMLDelegate()
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = false
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate
        guard parser.parse() || !delegate.roots.isEmpty else {
            throw FeedParserError.malformed(parser.parserError?.localizedDescription ?? "invalid OPML")
        }
        return OPMLDocument(title: delegate.title, dateCreated: delegate.dateCreated, outlines: delegate.roots)
    }

    public static func render(_ document: OPMLDocument) -> Data {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<opml version=\"2.0\" xmlns:tributary=\"\(namespace)\">\n"
        xml += "  <head>\n"
        xml += "    <title>\(HTMLText.escape(document.title))</title>\n"
        if let date = document.dateCreated {
            xml += "    <dateCreated>\(rfc822(date))</dateCreated>\n"
        }
        xml += "  </head>\n  <body>\n"
        for outline in document.outlines {
            xml += renderOutline(outline, indent: 2)
        }
        xml += "  </body>\n</opml>\n"
        return Data(xml.utf8)
    }

    private static func renderOutline(_ outline: OPMLOutline, indent: Int) -> String {
        let pad = String(repeating: "  ", count: indent)
        var attributes = "text=\"\(HTMLText.escape(outline.text))\""
        if let title = outline.title, title != outline.text { attributes += " title=\"\(HTMLText.escape(title))\"" }
        if let type = outline.type ?? (outline.isFeed ? "rss" : nil) { attributes += " type=\"\(HTMLText.escape(type))\"" }
        if let xml = outline.xmlURL { attributes += " xmlUrl=\"\(HTMLText.escape(xml.absoluteString))\"" }
        if let html = outline.htmlURL { attributes += " htmlUrl=\"\(HTMLText.escape(html.absoluteString))\"" }
        for (key, value) in outline.attributes.sorted(by: { $0.key < $1.key }) {
            attributes += " \(key)=\"\(HTMLText.escape(value))\""
        }
        if outline.children.isEmpty {
            return "\(pad)<outline \(attributes)/>\n"
        }
        var result = "\(pad)<outline \(attributes)>\n"
        for child in outline.children { result += renderOutline(child, indent: indent + 1) }
        result += "\(pad)</outline>\n"
        return result
    }

    private static func rfc822(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return formatter.string(from: date)
    }
}

private final class OPMLDelegate: NSObject, XMLParserDelegate {
    var title = "Subscriptions"
    var dateCreated: Date?
    var roots: [OPMLOutline] = []
    private var stack: [OPMLOutline] = []
    private var text = ""
    private var inHead = false
    private let dates = FeedDates()

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes: [String: String] = [:]) {
        text = ""
        switch elementName.lowercased() {
        case "head":
            inHead = true
        case "outline":
            var extra = attributes
            let text = extra.removeValue(forKey: "text") ?? extra["title"] ?? ""
            let title = extra.removeValue(forKey: "title")
            let xml = extra.removeValue(forKey: "xmlUrl").flatMap { URL(string: $0.trimmed) }
            let html = extra.removeValue(forKey: "htmlUrl").flatMap { URL(string: $0.trimmed) }
            let type = extra.removeValue(forKey: "type")
            extra.removeValue(forKey: "version")
            stack.append(OPMLOutline(text: text, title: title, xmlURL: xml, htmlURL: html, type: type, attributes: extra))
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName.lowercased() {
        case "head":
            inHead = false
        case "title":
            if inHead, !text.trimmed.isEmpty { title = text.trimmed }
        case "datecreated":
            if inHead { dateCreated = dates.parse(text) }
        case "outline":
            guard let outline = stack.popLast() else { return }
            if stack.isEmpty {
                roots.append(outline)
            } else {
                stack[stack.count - 1].children.append(outline)
            }
        default:
            break
        }
        text = ""
    }
}
