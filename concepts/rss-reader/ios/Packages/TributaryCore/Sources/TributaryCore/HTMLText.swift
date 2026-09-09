import Foundation

/// Small, dependency-free helpers for the HTML that feeds carry. These are deliberately
/// not a DOM: they are fast, predictable, and good enough for titles, summaries, and
/// word counts. Article rendering goes through `HTMLBlocks` instead.
public enum HTMLText {
    /// Strips tags, decodes entities, and collapses whitespace.
    public static func plainText(_ html: String) -> String {
        var output = ""
        output.reserveCapacity(html.count)
        var inTag = false
        var tagName = ""
        var skipDepth = 0
        var index = html.startIndex
        while index < html.endIndex {
            let character = html[index]
            if character == "<" {
                inTag = true
                tagName = ""
                index = html.index(after: index)
                continue
            }
            if inTag {
                if character == ">" {
                    inTag = false
                    let lowered = tagName.lowercased()
                    if lowered.hasPrefix("script") || lowered.hasPrefix("style") { skipDepth += 1 }
                    if lowered.hasPrefix("/script") || lowered.hasPrefix("/style") { skipDepth = max(0, skipDepth - 1) }
                    if lowered.hasPrefix("br") || lowered.hasPrefix("/p") || lowered.hasPrefix("/div") || lowered.hasPrefix("/li") || lowered.hasPrefix("/h") {
                        output.append(" ")
                    }
                } else if tagName.count < 12 {
                    tagName.append(character)
                }
                index = html.index(after: index)
                continue
            }
            if skipDepth == 0 { output.append(character) }
            index = html.index(after: index)
        }
        return collapseWhitespace(decodeEntities(output))
    }

    public static func collapseWhitespace(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)
        var pendingSpace = false
        for scalar in text.unicodeScalars {
            if scalar == "\u{00A0}" || CharacterSet.whitespacesAndNewlines.contains(scalar) {
                pendingSpace = true
            } else {
                if pendingSpace, !result.isEmpty { result.append(" ") }
                pendingSpace = false
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    private static let namedEntities: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{00A0}",
        "mdash": "\u{2014}", "ndash": "\u{2013}", "hellip": "\u{2026}", "rsquo": "\u{2019}", "lsquo": "\u{2018}",
        "rdquo": "\u{201D}", "ldquo": "\u{201C}", "copy": "\u{00A9}", "reg": "\u{00AE}", "trade": "\u{2122}",
        "laquo": "\u{00AB}", "raquo": "\u{00BB}", "middot": "\u{00B7}", "bull": "\u{2022}", "euro": "\u{20AC}",
        "pound": "\u{00A3}", "yen": "\u{00A5}", "deg": "\u{00B0}", "times": "\u{00D7}", "eacute": "\u{00E9}",
        "egrave": "\u{00E8}", "agrave": "\u{00E0}", "ccedil": "\u{00E7}", "uuml": "\u{00FC}", "ouml": "\u{00F6}",
        "auml": "\u{00E4}", "szlig": "\u{00DF}", "ntilde": "\u{00F1}", "iexcl": "\u{00A1}", "iquest": "\u{00BF}",
    ]

    /// Decodes named and numeric character references. Unknown names are left as written.
    public static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }
        var output = ""
        output.reserveCapacity(text.count)
        var index = text.startIndex
        while index < text.endIndex {
            guard text[index] == "&" else {
                output.append(text[index])
                index = text.index(after: index)
                continue
            }
            guard let semicolon = text[index...].firstIndex(of: ";"),
                  text.distance(from: index, to: semicolon) <= 10 else {
                output.append("&")
                index = text.index(after: index)
                continue
            }
            let body = String(text[text.index(after: index)..<semicolon])
            var replacement: String?
            if body.hasPrefix("#x") || body.hasPrefix("#X") {
                if let code = UInt32(body.dropFirst(2), radix: 16), let scalar = Unicode.Scalar(code) { replacement = String(scalar) }
            } else if body.hasPrefix("#") {
                if let code = UInt32(body.dropFirst()), let scalar = Unicode.Scalar(code) { replacement = String(scalar) }
            } else {
                replacement = namedEntities[body]
            }
            if let replacement {
                output.append(replacement)
                index = text.index(after: semicolon)
            } else {
                output.append("&")
                index = text.index(after: index)
            }
        }
        return output
    }

    public static func escape(_ text: String) -> String {
        var output = ""
        output.reserveCapacity(text.count)
        for character in text {
            switch character {
            case "&": output.append("&amp;")
            case "<": output.append("&lt;")
            case ">": output.append("&gt;")
            case "\"": output.append("&quot;")
            default: output.append(character)
            }
        }
        return output
    }

    /// Wraps plain text in paragraphs so it can flow through the same renderer as HTML.
    public static func escapedParagraphs(_ text: String) -> String {
        text.components(separatedBy: "\n\n")
            .map { "<p>" + escape($0.trimmed).replacingOccurrences(of: "\n", with: "<br>") + "</p>" }
            .joined()
    }

    /// First `<img src>` in the markup, resolved against `base`. Tracking pixels (1x1) are skipped
    /// when the width or height attribute says so.
    public static func firstImageURL(in html: String, base: URL?) -> URL? {
        for tag in HTMLTokenizer.tags(named: "img", in: html) {
            guard let src = tag["src"] ?? tag["data-src"], !src.isEmpty else { continue }
            if tag["width"] == "1" || tag["height"] == "1" { continue }
            if src.hasPrefix("data:") { continue }
            if let url = URL(string: src, relativeTo: base)?.absoluteURL { return url }
        }
        return nil
    }

    public static func wordCount(_ text: String) -> Int {
        var count = 0
        var inWord = false
        for scalar in text.unicodeScalars {
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                inWord = false
            } else if !inWord {
                inWord = true
                count += 1
            }
        }
        return count
    }
}

/// Reading time at 230 words per minute, never below one minute.
public enum ReadingTime {
    public static let wordsPerMinute = 230

    public static func minutes(wordCount: Int) -> Int {
        max(1, Int((Double(wordCount) / Double(wordsPerMinute)).rounded(.up)))
    }

    public static func minutes(text: String) -> Int {
        minutes(wordCount: HTMLText.wordCount(text))
    }
}

/// FNV-1a 64 as a hex string. Not cryptographic; used for item fingerprints and guid fallbacks.
public enum Fingerprint {
    public static func make(_ parts: String...) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for part in parts {
            for byte in part.utf8 {
                hash ^= UInt64(byte)
                hash = hash &* 0x0000_0100_0000_01B3
            }
            hash ^= 0x1F
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return String(hash, radix: 16)
    }
}
