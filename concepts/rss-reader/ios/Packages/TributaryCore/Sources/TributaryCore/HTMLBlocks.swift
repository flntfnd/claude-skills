import Foundation

/// A styled run of inline text. The renderer maps these onto `AttributedString`.
public struct InlineRun: Sendable, Hashable, Codable {
    public var text: String
    public var isBold: Bool
    public var isItalic: Bool
    public var isCode: Bool
    public var link: URL?

    public init(text: String, isBold: Bool = false, isItalic: Bool = false, isCode: Bool = false, link: URL? = nil) {
        self.text = text
        self.isBold = isBold
        self.isItalic = isItalic
        self.isCode = isCode
        self.link = link
    }
}

public struct InlineText: Sendable, Hashable, Codable {
    public var runs: [InlineRun]

    public init(runs: [InlineRun]) { self.runs = runs }
    public init(_ plain: String) { runs = [InlineRun(text: plain)] }

    public var plainText: String { runs.map(\.text).joined() }
    public var isBlank: Bool { plainText.trimmed.isEmpty }
    public var links: [URL] { runs.compactMap(\.link) }
}

/// The structural units the reader renders. Extraction keeps these intact where most
/// extractors flatten everything to paragraphs (CONCEPT.md, "extraction that keeps structure").
public enum ContentBlock: Sendable, Hashable, Codable {
    case heading(level: Int, text: InlineText)
    case paragraph(InlineText)
    case quote(InlineText)
    case image(url: URL, alt: String?, caption: String?)
    case code(String)
    case list(ordered: Bool, items: [InlineText])
    case rule

    public var plainText: String {
        switch self {
        case let .heading(_, text), let .paragraph(text), let .quote(text): return text.plainText
        case let .image(_, alt, caption): return caption ?? alt ?? ""
        case let .code(code): return code
        case let .list(_, items): return items.map(\.plainText).joined(separator: "\n")
        case .rule: return ""
        }
    }

    public var links: [URL] {
        switch self {
        case let .heading(_, text), let .paragraph(text), let .quote(text): return text.links
        case let .list(_, items): return items.flatMap(\.links)
        default: return []
        }
    }
}

public enum HTMLBlocks {
    /// Converts markup into blocks. `skipBoilerplate` drops nav, header, footer, aside, and form
    /// subtrees, which is right for a whole page and wrong for a feed body that is already the article.
    public static func blocks(from html: String, baseURL: URL?, skipBoilerplate: Bool = false) -> [ContentBlock] {
        var builder = BlockBuilder(baseURL: baseURL, skipBoilerplate: skipBoilerplate)
        for token in HTMLTokenizer.tokenize(html) {
            builder.consume(token)
        }
        return builder.finish()
    }

    public static func plainText(of blocks: [ContentBlock]) -> String {
        blocks.map(\.plainText).filter { !$0.isEmpty }.joined(separator: "\n\n")
    }
}

private struct BlockBuilder {
    let baseURL: URL?
    let skipBoilerplate: Bool

    private var blocks: [ContentBlock] = []
    private var runs: [InlineRun] = []
    private var bold = 0
    private var italic = 0
    private var code = 0
    private var links: [URL?] = []
    private var headingLevel: Int?
    private var quoteDepth = 0
    private var preDepth = 0
    private var preText = ""
    private var lists: [(ordered: Bool, items: [InlineText])] = []
    private var listItemOpen = false
    private var figureDepth = 0
    private var pendingImage: (url: URL, alt: String?)?
    private var captionRuns: [InlineRun]?
    private var skipDepth = 0
    private var boilerplateDepth = 0

    private static let boilerplate: Set<String> = ["nav", "header", "footer", "aside", "form", "button", "menu", "dialog"]
    private static let paragraphBreakers: Set<String> = ["p", "div", "section", "article", "main", "table", "tr", "td", "th", "dd", "dt", "dl", "details", "summary", "address", "center"]

    init(baseURL: URL?, skipBoilerplate: Bool) {
        self.baseURL = baseURL
        self.skipBoilerplate = skipBoilerplate
    }

    mutating func consume(_ token: HTMLToken) {
        switch token {
        case let .text(text):
            guard skipDepth == 0, boilerplateDepth == 0 else { return }
            if preDepth > 0 {
                preText += HTMLText.decodeEntities(text)
            } else {
                appendText(text)
            }
        case let .open(name, attributes, selfClosing):
            open(name, attributes: attributes)
            if selfClosing { close(name) }
        case let .close(name):
            close(name)
        }
    }

    mutating func finish() -> [ContentBlock] {
        flushParagraph()
        while !lists.isEmpty { closeList() }
        emitPendingImage()
        return blocks
    }

    private mutating func open(_ name: String, attributes: [String: String]) {
        if skipDepth > 0 { skipDepth += 1; return }
        if boilerplateDepth > 0 { boilerplateDepth += 1; return }
        if skipBoilerplate, Self.boilerplate.contains(name) { boilerplateDepth = 1; return }

        switch name {
        case "script", "style", "noscript", "svg", "iframe", "template", "select", "textarea":
            skipDepth = 1
        case "h1", "h2", "h3", "h4", "h5", "h6":
            flushParagraph()
            headingLevel = Int(String(name.last!)) ?? 2
        case "blockquote":
            flushParagraph()
            quoteDepth += 1
        case "pre":
            flushParagraph()
            preDepth += 1
            preText = ""
        case "ul", "ol":
            flushParagraph()
            lists.append((ordered: name == "ol", items: []))
        case "li":
            flushParagraph()
            listItemOpen = true
        case "br":
            if preDepth > 0 { preText += "\n" } else { runs.append(InlineRun(text: "\n", isBold: bold > 0, isItalic: italic > 0, isCode: code > 0, link: links.last ?? nil)) }
        case "hr":
            flushParagraph()
            blocks.append(.rule)
        case "img", "picture":
            if name == "img", let src = attributes["src"] ?? attributes["data-src"] ?? attributes["data-original"],
               !src.hasPrefix("data:"), attributes["width"] != "1", attributes["height"] != "1",
               let url = URL(string: src.trimmed, relativeTo: baseURL)?.absoluteURL {
                if figureDepth > 0 {
                    pendingImage = (url, attributes["alt"]?.trimmed)
                } else {
                    flushParagraph()
                    blocks.append(.image(url: url, alt: attributes["alt"]?.trimmed, caption: nil))
                }
            }
        case "figure":
            flushParagraph()
            figureDepth += 1
        case "figcaption":
            captionRuns = []
        case "a":
            let href = attributes["href"].flatMap { URL(string: $0.trimmed, relativeTo: baseURL)?.absoluteURL }
            links.append(href)
        case "strong", "b":
            bold += 1
        case "em", "i", "cite", "q":
            italic += 1
        case "code", "kbd", "samp", "tt":
            if preDepth == 0 { code += 1 }
        default:
            if Self.paragraphBreakers.contains(name) { flushParagraph() }
        }
    }

    private mutating func close(_ name: String) {
        if skipDepth > 0 { skipDepth -= 1; return }
        if boilerplateDepth > 0 { boilerplateDepth -= 1; return }

        switch name {
        case "h1", "h2", "h3", "h4", "h5", "h6":
            flushParagraph()
            headingLevel = nil
        case "blockquote":
            flushParagraph()
            quoteDepth = max(0, quoteDepth - 1)
        case "pre":
            preDepth = max(0, preDepth - 1)
            if preDepth == 0 {
                let trimmed = preText.trimmingCharacters(in: .newlines)
                if !trimmed.isEmpty { blocks.append(.code(trimmed)) }
                preText = ""
            }
        case "ul", "ol":
            flushParagraph()
            closeList()
        case "li":
            flushParagraph()
            listItemOpen = false
        case "figure":
            flushParagraph()
            figureDepth = max(0, figureDepth - 1)
            emitPendingImage()
        case "figcaption":
            if let caption = captionRuns, pendingImage != nil {
                captionText = InlineText(runs: caption).plainText.trimmed
            } else if let caption = captionRuns {
                runs.append(contentsOf: caption)
            }
            captionRuns = nil
        case "a":
            if !links.isEmpty { links.removeLast() }
        case "strong", "b":
            bold = max(0, bold - 1)
        case "em", "i", "cite", "q":
            italic = max(0, italic - 1)
        case "code", "kbd", "samp", "tt":
            if preDepth == 0 { code = max(0, code - 1) }
        default:
            if Self.paragraphBreakers.contains(name) { flushParagraph() }
        }
    }

    private var captionText: String?

    private mutating func appendText(_ raw: String) {
        let decoded = HTMLText.decodeEntities(raw)
        let collapsed = collapseInline(decoded)
        guard !collapsed.isEmpty else { return }
        let run = InlineRun(text: collapsed, isBold: bold > 0, isItalic: italic > 0, isCode: code > 0, link: links.last ?? nil)
        if captionRuns != nil {
            captionRuns?.append(run)
        } else {
            runs.append(run)
        }
    }

    /// Collapses whitespace inside a run but keeps one leading or trailing space so words
    /// split across tags ("<b>bold</b> next") don't fuse.
    private func collapseInline(_ text: String) -> String {
        let leading = text.first.map { $0.isWhitespace } ?? false
        let trailing = text.last.map { $0.isWhitespace } ?? false
        let core = HTMLText.collapseWhitespace(text)
        if core.isEmpty { return leading || trailing ? " " : "" }
        return (leading ? " " : "") + core + (trailing ? " " : "")
    }

    private mutating func flushParagraph() {
        let text = trimmedInline(runs)
        runs = []
        guard let text, !text.isBlank else { return }
        if listItemOpen || !lists.isEmpty, !lists.isEmpty {
            lists[lists.count - 1].items.append(text)
            return
        }
        if let level = headingLevel {
            blocks.append(.heading(level: level, text: text))
        } else if quoteDepth > 0 {
            blocks.append(.quote(text))
        } else {
            blocks.append(.paragraph(text))
        }
    }

    private func trimmedInline(_ runs: [InlineRun]) -> InlineText? {
        guard !runs.isEmpty else { return nil }
        var result = runs
        // Merge adjacent runs with identical style so the renderer gets fewer attribute boundaries.
        var merged: [InlineRun] = []
        for run in result {
            if var last = merged.last, last.isBold == run.isBold, last.isItalic == run.isItalic, last.isCode == run.isCode, last.link == run.link {
                last.text += run.text
                merged[merged.count - 1] = last
            } else {
                merged.append(run)
            }
        }
        result = merged
        if var first = result.first {
            first.text = String(first.text.drop(while: { $0.isWhitespace }))
            result[0] = first
        }
        if var last = result.last {
            while last.text.last?.isWhitespace == true { last.text.removeLast() }
            result[result.count - 1] = last
        }
        result.removeAll { $0.text.isEmpty }
        // Collapse runs of spaces created at tag boundaries.
        for index in result.indices {
            while result[index].text.contains("  ") {
                result[index].text = result[index].text.replacingOccurrences(of: "  ", with: " ")
            }
        }
        return result.isEmpty ? nil : InlineText(runs: result)
    }

    private mutating func closeList() {
        guard let list = lists.popLast() else { return }
        listItemOpen = !lists.isEmpty
        guard !list.items.isEmpty else { return }
        if !lists.isEmpty {
            // Nested list: fold its items into the parent as indented lines.
            for item in list.items {
                lists[lists.count - 1].items.append(InlineText(runs: [InlineRun(text: "    ")] + item.runs))
            }
        } else {
            blocks.append(.list(ordered: list.ordered, items: list.items))
        }
    }

    private mutating func emitPendingImage() {
        guard let image = pendingImage else { return }
        blocks.append(.image(url: image.url, alt: image.alt, caption: captionText))
        pendingImage = nil
        captionText = nil
    }
}
