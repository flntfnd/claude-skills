import Foundation

/// Normalizes URLs so the same article arriving through two feeds is one item, and so
/// exported state matches on another reader. The rules are conservative: strip what is
/// known to be tracking, never rewrite the path.
public enum CanonicalURL {
    private static let trackingParameters: Set<String> = [
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "utm_id", "utm_name",
        "fbclid", "gclid", "dclid", "msclkid", "mc_cid", "mc_eid", "igshid", "ref_src", "ref_url",
        "_hsenc", "_hsmi", "hsctatracking", "yclid", "twclid", "vero_id", "wickedid", "oly_enc_id", "oly_anon_id",
        "s_cid", "cmpid", "mkt_tok", "trk", "trkcampaign", "sr_share", "ocid", "ncid",
    ]

    public static func normalize(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return url.absoluteString
        }
        components.scheme = components.scheme?.lowercased()
        if components.scheme == "http" { components.scheme = "https" }
        if let host = components.host?.lowercased() {
            components.host = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        }
        if let port = components.port, (port == 80 && components.scheme == "http") || (port == 443 && components.scheme == "https") {
            components.port = nil
        }
        components.fragment = nil
        if let items = components.queryItems {
            let kept = items
                .filter { !trackingParameters.contains($0.name.lowercased()) && !$0.name.lowercased().hasPrefix("utm_") }
                .sorted { $0.name < $1.name }
            components.queryItems = kept.isEmpty ? nil : kept
        }
        var path = components.path
        if path.count > 1, path.hasSuffix("/") { path.removeLast() }
        if path.isEmpty { path = "/" }
        components.path = path
        return components.string ?? url.absoluteString
    }

    public static func normalize(_ string: String) -> String {
        guard let url = URL(string: string.trimmed) else { return string.trimmed }
        return normalize(url)
    }

    /// Turns whatever a person pastes into something fetchable: adds a scheme, trims, and
    /// handles the `feed:` scheme readers hand each other.
    public static func fetchable(fromInput input: String) -> URL? {
        var text = input.trimmed
        guard !text.isEmpty else { return nil }
        if text.lowercased().hasPrefix("feed://") { text = "https://" + text.dropFirst(7) }
        if text.lowercased().hasPrefix("feed:") { text = String(text.dropFirst(5)) }
        if !text.contains("://") { text = "https://" + text }
        return URL(string: text)
    }
}
