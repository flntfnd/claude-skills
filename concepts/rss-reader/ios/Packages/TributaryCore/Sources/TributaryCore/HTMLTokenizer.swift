import Foundation

/// A forgiving HTML tokenizer. Real-world feed HTML is rarely well-formed XML, so
/// `XMLParser` is the wrong tool. This walks the string once and produces tags and
/// text runs; `HTMLBlocks` turns those into rendering blocks.
enum HTMLToken: Equatable {
    case text(String)
    case open(name: String, attributes: [String: String], selfClosing: Bool)
    case close(name: String)
}

enum HTMLTokenizer {
    private static let rawTextElements: Set<String> = ["script", "style", "noscript", "svg", "iframe", "textarea", "template"]

    static func tokenize(_ html: String) -> [HTMLToken] {
        var tokens: [HTMLToken] = []
        var text = ""
        var index = html.startIndex
        let end = html.endIndex

        func flushText() {
            if !text.isEmpty {
                tokens.append(.text(text))
                text = ""
            }
        }

        while index < end {
            let character = html[index]
            guard character == "<" else {
                text.append(character)
                index = html.index(after: index)
                continue
            }
            let next = html.index(after: index)
            guard next < end else { text.append(character); index = next; continue }
            let peek = html[next]

            if peek == "!" {
                // Comment, doctype, or CDATA. Skip to the end of it.
                if html[next...].hasPrefix("!--") {
                    if let close = html.range(of: "-->", range: next..<end) {
                        index = close.upperBound
                    } else {
                        index = end
                    }
                } else if let close = html[next...].firstIndex(of: ">") {
                    index = html.index(after: close)
                } else {
                    index = end
                }
                continue
            }

            guard peek == "/" || peek.isLetter else {
                text.append(character)
                index = next
                continue
            }

            guard let tagEnd = tagEndIndex(in: html, from: next) else {
                text.append(character)
                index = next
                continue
            }
            flushText()
            let inner = String(html[next..<tagEnd])
            index = html.index(after: tagEnd)

            if inner.hasPrefix("/") {
                let name = inner.dropFirst().trimmed.lowercased()
                tokens.append(.close(name: String(name)))
                continue
            }

            let (name, attributes, selfClosing) = parseTag(inner)
            tokens.append(.open(name: name, attributes: attributes, selfClosing: selfClosing))

            if rawTextElements.contains(name), !selfClosing {
                // Skip everything until the matching close tag; contents are never rendered.
                let closeTag = "</" + name
                if let closeRange = html.range(of: closeTag, options: .caseInsensitive, range: index..<end),
                   let gt = html[closeRange.upperBound...].firstIndex(of: ">") {
                    index = html.index(after: gt)
                } else {
                    index = end
                }
                tokens.append(.close(name: name))
            }
        }
        flushText()
        return tokens
    }

    /// Every tag with the given name, as attribute dictionaries. Used for quick lookups
    /// (first image, link rel alternate) without building blocks.
    static func tags(named wanted: String, in html: String) -> [[String: String]] {
        var results: [[String: String]] = []
        for token in tokenize(html) {
            if case let .open(name, attributes, _) = token, name == wanted {
                results.append(attributes)
            }
        }
        return results
    }

    private static func tagEndIndex(in html: String, from start: String.Index) -> String.Index? {
        var index = start
        var quote: Character?
        while index < html.endIndex {
            let character = html[index]
            if let open = quote {
                if character == open { quote = nil }
            } else if character == "\"" || character == "'" {
                quote = character
            } else if character == ">" {
                return index
            }
            index = html.index(after: index)
        }
        return nil
    }

    private static func parseTag(_ inner: String) -> (String, [String: String], Bool) {
        var body = Substring(inner)
        var selfClosing = false
        if body.hasSuffix("/") {
            selfClosing = true
            body = body.dropLast()
        }
        let nameEnd = body.firstIndex(where: { $0 == " " || $0 == "\n" || $0 == "\t" || $0 == "\r" }) ?? body.endIndex
        let name = body[..<nameEnd].lowercased()
        var attributes: [String: String] = [:]
        var rest = body[nameEnd...]
        while true {
            rest = rest.drop(while: { $0.isWhitespace })
            guard let first = rest.first else { break }
            guard first.isLetter || first == "_" || first == ":" || first == "@" || first == "-" else {
                rest = rest.dropFirst()
                continue
            }
            let keyEnd = rest.firstIndex(where: { $0 == "=" || $0.isWhitespace }) ?? rest.endIndex
            let key = rest[..<keyEnd].lowercased()
            rest = rest[keyEnd...].drop(while: { $0.isWhitespace })
            if rest.first == "=" {
                rest = rest.dropFirst().drop(while: { $0.isWhitespace })
                if let quote = rest.first, quote == "\"" || quote == "'" {
                    rest = rest.dropFirst()
                    let valueEnd = rest.firstIndex(of: quote) ?? rest.endIndex
                    attributes[key] = HTMLText.decodeEntities(String(rest[..<valueEnd]))
                    rest = valueEnd < rest.endIndex ? rest[rest.index(after: valueEnd)...] : rest[valueEnd...]
                } else {
                    let valueEnd = rest.firstIndex(where: { $0.isWhitespace }) ?? rest.endIndex
                    attributes[key] = HTMLText.decodeEntities(String(rest[..<valueEnd]))
                    rest = rest[valueEnd...]
                }
            } else {
                attributes[key] = ""
            }
        }
        let voidElements: Set<String> = ["br", "img", "hr", "meta", "link", "input", "source", "wbr", "area", "base", "col", "embed", "param", "track"]
        return (name, attributes, selfClosing || voidElements.contains(name))
    }
}
