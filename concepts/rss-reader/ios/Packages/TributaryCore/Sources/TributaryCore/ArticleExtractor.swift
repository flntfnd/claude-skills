import Foundation

public struct ExtractedArticle: Sendable, Hashable {
    public var title: String?
    public var author: String?
    public var leadImageURL: URL?
    public var blocks: [ContentBlock]

    public var plainText: String { HTMLBlocks.plainText(of: blocks) }
    public var wordCount: Int { HTMLText.wordCount(plainText) }
}

/// Picks the article out of a full web page and turns it into blocks. This is a
/// heuristic, not a DOM-scoring readability port: it prefers `<article>`, then `<main>`,
/// then the body with boilerplate subtrees removed, and trims the short lead-in lines
/// that survive. Good enough to be honest about, and the fixture suite in
/// `ArticleExtractorTests` is where it gets better one real page at a time.
public enum ArticleExtractor {
    public static func extract(html: String, baseURL: URL?) -> ExtractedArticle {
        let region = articleRegion(in: html)
        var blocks = HTMLBlocks.blocks(from: region, baseURL: baseURL, skipBoilerplate: true)
        blocks = trimLeadIn(blocks)
        let title = metaContent(in: html, property: "og:title") ?? titleTag(in: html)
        let author = metaContent(in: html, name: "author") ?? metaContent(in: html, property: "article:author")
        let lead = metaContent(in: html, property: "og:image").flatMap { URL(string: $0, relativeTo: baseURL)?.absoluteURL }
            ?? blocks.lazy.compactMap { block -> URL? in
                if case let .image(url, _, _) = block { return url }
                return nil
            }.first
        return ExtractedArticle(title: title.map(HTMLText.plainText), author: author, leadImageURL: lead, blocks: blocks)
    }

    /// Returns the inner markup of the best container. Falls back to the whole document.
    static func articleRegion(in html: String) -> String {
        for tag in ["article", "main"] {
            let candidates = innerHTML(of: tag, in: html)
            if let best = candidates.max(by: { HTMLText.plainText($0).count < HTMLText.plainText($1).count }),
               HTMLText.plainText(best).count > 400 {
                return best
            }
        }
        if let body = innerHTML(of: "body", in: html).first { return body }
        return html
    }

    /// Inner HTML for every occurrence of `tag`, matched by nesting depth.
    static func innerHTML(of tag: String, in html: String) -> [String] {
        var results: [String] = []
        var search = html.startIndex
        while let open = html.range(of: "<" + tag, options: .caseInsensitive, range: search..<html.endIndex) {
            // Make sure this is the element and not a prefix (e.g. <mainframe>).
            let afterName = open.upperBound
            if afterName < html.endIndex, html[afterName].isLetter || html[afterName] == "-" {
                search = afterName
                continue
            }
            guard let gt = html[open.upperBound...].firstIndex(of: ">") else { break }
            let contentStart = html.index(after: gt)
            var depth = 1
            var cursor = contentStart
            var contentEnd: String.Index?
            while depth > 0, let lt = html[cursor...].firstIndex(of: "<") {
                let rest = html[lt...]
                if rest.range(of: "</" + tag, options: [.caseInsensitive, .anchored]) != nil {
                    depth -= 1
                    if depth == 0 { contentEnd = lt; break }
                } else if rest.range(of: "<" + tag, options: [.caseInsensitive, .anchored]) != nil {
                    if let nameEnd = html.index(lt, offsetBy: tag.count + 1, limitedBy: html.endIndex) {
                        if nameEnd == html.endIndex || !(html[nameEnd].isLetter || html[nameEnd] == "-") { depth += 1 }
                    }
                }
                cursor = html.index(after: lt)
            }
            if let contentEnd {
                results.append(String(html[contentStart..<contentEnd]))
                search = contentEnd
            } else {
                results.append(String(html[contentStart...]))
                break
            }
        }
        return results
    }

    /// Drops share buttons, bylines and breadcrumbs that show up before the first real paragraph.
    static func trimLeadIn(_ blocks: [ContentBlock]) -> [ContentBlock] {
        guard let start = blocks.firstIndex(where: { block in
            switch block {
            case .heading: return true
            case let .paragraph(text): return text.plainText.count >= 60
            case .image, .quote, .list, .code: return true
            case .rule: return false
            }
        }) else { return blocks }
        return Array(blocks[start...])
    }

    static func titleTag(in html: String) -> String? {
        guard let open = html.range(of: "<title", options: .caseInsensitive),
              let gt = html[open.upperBound...].firstIndex(of: ">"),
              let close = html.range(of: "</title>", options: .caseInsensitive, range: gt..<html.endIndex) else { return nil }
        let raw = String(html[html.index(after: gt)..<close.lowerBound])
        let cleaned = HTMLText.plainText(raw)
        return cleaned.isEmpty ? nil : cleaned
    }

    static func metaContent(in html: String, property: String? = nil, name: String? = nil) -> String? {
        for tag in HTMLTokenizer.tags(named: "meta", in: html) {
            if let property, tag["property"]?.lowercased() == property, let content = tag["content"], !content.isEmpty { return content }
            if let name, tag["name"]?.lowercased() == name, let content = tag["content"], !content.isEmpty { return content }
        }
        return nil
    }
}

/// Finds feeds advertised by a web page, plus the usual guesses when a page advertises none.
public enum FeedDiscovery {
    private static let feedTypes: Set<String> = [
        "application/rss+xml", "application/atom+xml", "application/feed+json", "application/json", "application/rdf+xml", "text/xml",
    ]

    public static func advertisedFeeds(inHTML html: String, baseURL: URL) -> [URL] {
        var seen = Set<String>()
        var results: [URL] = []
        for tag in HTMLTokenizer.tags(named: "link", in: html) {
            let rel = (tag["rel"] ?? "").lowercased().split(separator: " ")
            guard rel.contains("alternate"), let type = tag["type"]?.lowercased(), feedTypes.contains(type),
                  let href = tag["href"], let url = URL(string: href.trimmed, relativeTo: baseURL)?.absoluteURL else { continue }
            if seen.insert(url.absoluteString).inserted { results.append(url) }
        }
        return results
    }

    /// Paths worth trying when a site has no `<link rel="alternate">`, most common first.
    public static func guesses(for site: URL) -> [URL] {
        let paths = ["/feed", "/feed/", "/rss", "/rss.xml", "/feed.xml", "/atom.xml", "/index.xml", "/feed.json", "/feeds/posts/default", "/?feed=rss2", "/blog/feed", "/rss/index.xml"]
        var base = site
        if base.path.isEmpty { base = base.appending(path: "/") }
        return paths.compactMap { URL(string: $0, relativeTo: base)?.absoluteURL }
    }

    /// Well-known hosts publish feeds at predictable places. Handles the ones people paste most.
    public static func platformFeed(for url: URL) -> URL? {
        guard let host = url.host()?.lowercased() else { return nil }
        let path = url.path()
        if host.contains("youtube.com") {
            if let id = url.queryValue("list") { return URL(string: "https://www.youtube.com/feeds/videos.xml?playlist_id=\(id)") }
            if path.hasPrefix("/channel/") { return URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=\(path.dropFirst(9))") }
        }
        if host.contains("substack.com"), !path.hasSuffix("/feed") {
            return URL(string: "https://\(host)/feed")
        }
        if host.contains("medium.com"), !path.hasPrefix("/feed") {
            return URL(string: "https://\(host)/feed\(path)")
        }
        if host == "github.com" {
            let parts = path.split(separator: "/")
            if parts.count >= 2 { return URL(string: "https://github.com/\(parts[0])/\(parts[1])/releases.atom") }
        }
        if host.hasSuffix("reddit.com"), !path.hasSuffix(".rss") {
            return URL(string: "https://www.reddit.com\(path.hasSuffix("/") ? String(path.dropLast()) : path).rss")
        }
        return nil
    }
}

extension URL {
    func queryValue(_ name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == name }?.value
    }
}
