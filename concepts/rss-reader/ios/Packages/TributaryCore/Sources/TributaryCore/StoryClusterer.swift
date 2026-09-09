import Foundation

/// Input to clustering: one item, stripped to what similarity is computed on.
public struct ClusterCandidate: Sendable, Hashable {
    public var id: String
    public var title: String
    public var canonicalURL: String?
    public var outboundLinks: [String]
    public var published: Date?
    public var isPriority: Bool

    public init(id: String, title: String, canonicalURL: String?, outboundLinks: [String] = [], published: Date?, isPriority: Bool = false) {
        self.id = id
        self.title = title
        self.canonicalURL = canonicalURL
        self.outboundLinks = outboundLinks
        self.published = published
        self.isPriority = isPriority
    }
}

public struct StoryCluster: Sendable, Hashable {
    /// The item that leads the row: the Priority-lane source if there is one, otherwise the earliest.
    public var leadID: String
    public var memberIDs: [String]
    public var reason: Reason

    public enum Reason: String, Sendable, Codable { case sameURL, sharedLink, similarTitle }

    public var count: Int { memberIDs.count }
}

/// Groups items that cover the same story. Deterministic and explainable: the same canonical
/// URL, a shared outbound link, or near-identical titles inside a time window. No model, no
/// ranking. The user can always see why two items were grouped.
public enum StoryClusterer {
    private static let stopWords: Set<String> = [
        "a", "an", "the", "and", "or", "of", "to", "in", "on", "for", "with", "at", "by", "from", "is", "are", "was", "were",
        "be", "as", "it", "its", "this", "that", "these", "those", "new", "how", "why", "what", "when", "will", "can", "you", "your",
        "we", "our", "i", "my", "me", "he", "she", "they", "them", "his", "her", "their", "has", "have", "had", "not", "no", "but", "so",
        "up", "out", "over", "into", "about", "after", "before", "just", "more", "most", "than", "here", "heres", "there",
    ]

    public static func clusters(
        _ candidates: [ClusterCandidate],
        window: TimeInterval = 36 * 3600,
        titleThreshold: Double = 0.6
    ) -> [StoryCluster] {
        guard candidates.count > 1 else { return [] }
        var parent = Array(candidates.indices)
        var reasons: [Int: StoryCluster.Reason] = [:]

        func find(_ index: Int) -> Int {
            var root = index
            while parent[root] != root { root = parent[root] }
            var cursor = index
            while parent[cursor] != root {
                let next = parent[cursor]
                parent[cursor] = root
                cursor = next
            }
            return root
        }

        func union(_ a: Int, _ b: Int, _ reason: StoryCluster.Reason) {
            let rootA = find(a), rootB = find(b)
            guard rootA != rootB else { return }
            parent[rootB] = rootA
            if reasons[rootA] == nil { reasons[rootA] = reason }
        }

        let tokens = candidates.map { tokenSet($0.title) }
        let urls = candidates.map { $0.canonicalURL.map { $0.lowercased() } }
        let links = candidates.map { Set($0.outboundLinks.map { $0.lowercased() }) }

        for i in candidates.indices {
            for j in (i + 1)..<candidates.count {
                if let a = candidates[i].published, let b = candidates[j].published, abs(a.timeIntervalSince(b)) > window {
                    continue
                }
                if let u = urls[i], let v = urls[j], u == v {
                    union(i, j, .sameURL)
                    continue
                }
                if let u = urls[i], links[j].contains(u) { union(i, j, .sharedLink); continue }
                if let v = urls[j], links[i].contains(v) { union(i, j, .sharedLink); continue }
                if !links[i].isEmpty, !links[j].isEmpty, !links[i].isDisjoint(with: links[j]) { union(i, j, .sharedLink); continue }
                if jaccard(tokens[i], tokens[j]) >= titleThreshold { union(i, j, .similarTitle) }
            }
        }

        var groups: [Int: [Int]] = [:]
        for index in candidates.indices { groups[find(index), default: []].append(index) }

        return groups.values
            .filter { $0.count > 1 }
            .map { members in
                let lead = members.min { lhs, rhs in
                    let l = candidates[lhs], r = candidates[rhs]
                    if l.isPriority != r.isPriority { return l.isPriority }
                    return (l.published ?? .distantFuture) < (r.published ?? .distantFuture)
                }!
                let ordered = members.sorted { (candidates[$0].published ?? .distantPast) > (candidates[$1].published ?? .distantPast) }
                return StoryCluster(leadID: candidates[lead].id, memberIDs: ordered.map { candidates[$0].id }, reason: reasons[find(lead)] ?? .similarTitle)
            }
            .sorted { $0.count > $1.count }
    }

    static func tokenSet(_ title: String) -> Set<String> {
        let lowered = title.lowercased()
        var tokens = Set<String>()
        var current = ""
        for scalar in lowered.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                current.unicodeScalars.append(scalar)
            } else {
                if current.count > 1, !stopWords.contains(current) { tokens.insert(current) }
                current = ""
            }
        }
        if current.count > 1, !stopWords.contains(current) { tokens.insert(current) }
        return tokens
    }

    static func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        let intersection = a.intersection(b).count
        guard intersection >= 3 else { return 0 }
        return Double(intersection) / Double(a.union(b).count)
    }
}
