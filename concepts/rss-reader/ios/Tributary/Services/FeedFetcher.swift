import Foundation
import TributaryCore

/// Network layer for feeds and pages. Conditional GET with ETag and Last-Modified so an
/// unchanged feed costs a 304, a User-Agent that identifies the app, and a hard cap on
/// concurrent connections so a 400-feed library doesn't open 400 sockets.
enum FeedFetcher {
    static let userAgent = "Tributary/0.1 (+https://tributary.app; RSS reader)"
    static let maxBytes = 12 * 1024 * 1024

    struct Job: Sendable {
        var feedID: UUID
        var url: String
        var etag: String?
        var lastModified: String?
    }

    enum Result: Sendable {
        case fetched(ParsedFeed, etag: String?, lastModified: String?)
        case notModified
        case failed(String)
    }

    static func fetchAll(_ jobs: [Job], session: URLSession, concurrency: Int) async -> [UUID: Result] {
        var results: [UUID: Result] = [:]
        await withTaskGroup(of: (UUID, Result).self) { group in
            var next = 0
            let initial = min(max(1, concurrency), jobs.count)
            while next < initial {
                let job = jobs[next]
                next += 1
                group.addTask { (job.feedID, await fetch(job, session: session)) }
            }
            for await (id, result) in group {
                results[id] = result
                if next < jobs.count {
                    let job = jobs[next]
                    next += 1
                    group.addTask { (job.feedID, await fetch(job, session: session)) }
                }
            }
        }
        return results
    }

    static func fetch(_ job: Job, session: URLSession) async -> Result {
        guard let url = URL(string: job.url) else { return .failed("Invalid URL") }
        var request = URLRequest(url: url)
        request.setValue("application/rss+xml, application/atom+xml, application/feed+json, application/xml;q=0.9, text/xml;q=0.8, */*;q=0.5", forHTTPHeaderField: "Accept")
        if let etag = job.etag { request.setValue(etag, forHTTPHeaderField: "If-None-Match") }
        if let modified = job.lastModified { request.setValue(modified, forHTTPHeaderField: "If-Modified-Since") }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .failed("No HTTP response") }
            switch http.statusCode {
            case 304:
                return .notModified
            case 200..<300:
                guard data.count <= maxBytes else { return .failed("Feed is larger than 12 MB") }
                let parsed = try FeedParser.parse(data: data, sourceURL: url)
                return .fetched(parsed, etag: http.value(forHTTPHeaderField: "ETag"), lastModified: http.value(forHTTPHeaderField: "Last-Modified"))
            case 404, 410:
                return .failed("Feed is gone (\(http.statusCode))")
            case 429, 503:
                return .failed("Server asked us to slow down (\(http.statusCode))")
            default:
                return .failed("HTTP \(http.statusCode)")
            }
        } catch let error as FeedParserError {
            return .failed(describe(error))
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    /// Fetches a web page for extraction or discovery. Text only, capped, best-effort decoding.
    static func fetchPage(_ url: URL, session: URLSession = .shared) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("text/html, application/xhtml+xml, */*;q=0.5", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        guard data.count <= maxBytes else { throw URLError(.dataLengthExceedsMaximum) }
        if let text = String(data: data, encoding: .utf8) { return text }
        if let text = String(data: data, encoding: .isoLatin1) { return text }
        return String(decoding: data, as: UTF8.self)
    }

    /// Raw feed fetch used by discovery and preview, where there is no Feed record yet.
    static func fetchFeed(_ url: URL, session: URLSession = .shared) async throws -> ParsedFeed {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/rss+xml, application/atom+xml, application/feed+json, application/xml;q=0.9, text/xml;q=0.8, */*;q=0.5", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try FeedParser.parse(data: data, sourceURL: url)
    }

    static func describe(_ error: FeedParserError) -> String {
        switch error {
        case .empty: "The feed is empty"
        case .unrecognizedFormat: "Not an RSS, Atom, or JSON feed"
        case let .malformed(message): "Couldn’t read the feed: \(message)"
        }
    }
}
