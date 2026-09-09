import Foundation
import Testing
@testable import TributaryCore

@Suite("HTML text")
struct HTMLTextTests {
    @Test func stripsTagsAndDecodesEntities() {
        let text = HTMLText.plainText("<p>Hello&nbsp;<b>world</b> &amp; friends&#8217;s &#x27;quote&#x27;</p><script>alert(1)</script>")
        #expect(text == "Hello world & friends’s 'quote'")
    }

    @Test func countsWordsAndReadingTime() {
        let words = Array(repeating: "word", count: 700).joined(separator: " ")
        #expect(HTMLText.wordCount(words) == 700)
        #expect(ReadingTime.minutes(text: words) == 4)
        #expect(ReadingTime.minutes(wordCount: 10) == 1)
    }

    @Test func findsFirstRealImage() {
        let html = "<p><img src=\"https://t.co/pixel.gif\" width=\"1\" height=\"1\"><img src=\"/img/cover.jpg\" alt=\"Cover\"></p>"
        let url = HTMLText.firstImageURL(in: html, base: URL(string: "https://example.com/post/1"))
        #expect(url?.absoluteString == "https://example.com/img/cover.jpg")
    }
}

@Suite("HTML blocks")
struct HTMLBlocksTests {
    @Test func keepsStructure() throws {
        let html = """
        <h2>Here is the solution</h2>
        <p>Last week both <a href="https://google.com/maps">Google</a> and <strong>Apple</strong> updated their maps.</p>
        <blockquote><p>The car industry A/B tested selling a car.</p></blockquote>
        <ul><li>United States: Lake America</li><li>Canada: Lake Ontario</li></ul>
        <figure><img src="https://example.com/a.jpg" alt="Petra Heights"><figcaption>Petra Heights, Finchley Road</figcaption></figure>
        <pre><code>let x = 1
        print(x)</code></pre>
        <hr>
        <p>Done.</p>
        """
        let blocks = HTMLBlocks.blocks(from: html, baseURL: nil)
        #expect(blocks.count == 8)

        guard case let .heading(level, heading) = blocks[0] else { Issue.record("expected heading"); return }
        #expect(level == 2)
        #expect(heading.plainText == "Here is the solution")

        guard case let .paragraph(paragraph) = blocks[1] else { Issue.record("expected paragraph"); return }
        #expect(paragraph.plainText == "Last week both Google and Apple updated their maps.")
        #expect(paragraph.links.first?.absoluteString == "https://google.com/maps")
        #expect(paragraph.runs.contains { $0.isBold && $0.text == "Apple" })

        guard case let .quote(quote) = blocks[2] else { Issue.record("expected quote"); return }
        #expect(quote.plainText == "The car industry A/B tested selling a car.")

        guard case let .list(ordered, items) = blocks[3] else { Issue.record("expected list"); return }
        #expect(!ordered)
        #expect(items.map(\.plainText) == ["United States: Lake America", "Canada: Lake Ontario"])

        guard case let .image(url, alt, caption) = blocks[4] else { Issue.record("expected image"); return }
        #expect(url.absoluteString == "https://example.com/a.jpg")
        #expect(alt == "Petra Heights")
        #expect(caption == "Petra Heights, Finchley Road")

        guard case let .code(code) = blocks[5] else { Issue.record("expected code"); return }
        #expect(code.hasPrefix("let x = 1"))
        #expect(blocks[6] == .rule)
    }

    @Test func skipsScriptsAndBoilerplate() {
        let html = "<nav><a href='/'>Home</a></nav><p>Body text that is long enough to keep around for the reader.</p><script>var a = 1;</script><footer>© 2026</footer>"
        let blocks = HTMLBlocks.blocks(from: html, baseURL: nil, skipBoilerplate: true)
        #expect(blocks.count == 1)
        #expect(blocks.first?.plainText.hasPrefix("Body text") == true)
    }
}

@Suite("Article extraction")
struct ArticleExtractorTests {
    @Test func prefersArticleElement() {
        let html = """
        <html><head><title>Groupwork completes stone high-rise | Dezeen</title>
        <meta property="og:title" content="Groupwork completes stone high-rise">
        <meta property="og:image" content="https://static.dezeen.com/stone.jpg"></head>
        <body><header><nav>Menu</nav></header>
        <div class="promo"><p>Subscribe to our newsletter for daily updates and more things you did not ask for.</p></div>
        <article>
        <p>Share</p>
        <p>A thousand tons of volcanic rock replace concrete and steel in Petra Heights, a housing development in north London by architecture studio Groupwork and engineer Webb Yates.</p>
        <p>The apartment building consists of three blocks ranging from six to 10 storeys, held up entirely by an exoskeleton of unreinforced stone. Groupwork describes it as the first high-rise in the world to be supported this way, and the structure carries a fifth of the embodied carbon of concrete.</p>
        <p>Each block is carried by load-bearing columns of volcanic stone quarried in the Auvergne, post-tensioned with steel cables running through the core of every column. The floors are cross-laminated timber and the exoskeleton can be dismantled and reused.</p>
        </article>
        <footer>Footer</footer></body></html>
        """
        let article = ArticleExtractor.extract(html: html, baseURL: URL(string: "https://www.dezeen.com/2026/09/07/stone/"))
        #expect(article.title == "Groupwork completes stone high-rise")
        #expect(article.leadImageURL?.absoluteString == "https://static.dezeen.com/stone.jpg")
        #expect(article.blocks.count == 3)
        #expect(article.blocks.first?.plainText.hasPrefix("A thousand tons") == true)
        #expect(article.wordCount > 80)
    }

    @Test func discoversFeeds() {
        let html = "<html><head><link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" href=\"/feed\"><link rel=\"alternate\" type=\"application/json\" href=\"https://example.com/feed.json\"></head></html>"
        let feeds = FeedDiscovery.advertisedFeeds(inHTML: html, baseURL: URL(string: "https://example.com/post")!)
        #expect(feeds.map(\.absoluteString) == ["https://example.com/feed", "https://example.com/feed.json"])
        #expect(FeedDiscovery.platformFeed(for: URL(string: "https://github.com/RSSNext/Folo")!)?.absoluteString == "https://github.com/RSSNext/Folo/releases.atom")
        #expect(FeedDiscovery.guesses(for: URL(string: "https://example.com")!).first?.absoluteString == "https://example.com/feed")
    }
}

@Suite("Canonical URLs")
struct CanonicalURLTests {
    @Test func normalizes() {
        #expect(CanonicalURL.normalize("HTTP://WWW.Example.com/Post/?utm_source=x&b=2&a=1#top") == "https://example.com/Post?a=1&b=2")
        #expect(CanonicalURL.normalize("https://example.com") == "https://example.com/")
        #expect(CanonicalURL.normalize("https://example.com/a/") == "https://example.com/a")
    }

    @Test func fetchableFromInput() {
        #expect(CanonicalURL.fetchable(fromInput: "daringfireball.net")?.absoluteString == "https://daringfireball.net")
        #expect(CanonicalURL.fetchable(fromInput: "feed://example.com/rss")?.absoluteString == "https://example.com/rss")
        #expect(CanonicalURL.fetchable(fromInput: "  ") == nil)
    }
}

@Suite("Story clustering")
struct StoryClustererTests {
    @Test func groupsSameStory() {
        let now = Date()
        let candidates = [
            ClusterCandidate(id: "a", title: "Three new iPhones launch this week, here’s what’s coming", canonicalURL: "https://9to5mac.com/a", published: now, isPriority: false),
            ClusterCandidate(id: "b", title: "Apple’s three new iPhones launch this week: what’s coming", canonicalURL: "https://theverge.com/b", published: now.addingTimeInterval(-3600)),
            ClusterCandidate(id: "c", title: "Design overtakes retail as biggest contributor to UK economy", canonicalURL: "https://dezeen.com/c", published: now),
            ClusterCandidate(id: "d", title: "Linked: iPhone launch coverage", canonicalURL: "https://df.net/d", outboundLinks: ["https://9to5mac.com/a"], published: now, isPriority: true),
            ClusterCandidate(id: "e", title: "Same story syndicated", canonicalURL: "https://9to5mac.com/a", published: now.addingTimeInterval(-600)),
        ]
        let clusters = StoryClusterer.clusters(candidates)
        #expect(clusters.count == 1)
        let cluster = clusters[0]
        #expect(Set(cluster.memberIDs) == ["a", "b", "d", "e"])
        #expect(cluster.leadID == "d")
    }

    @Test func respectsWindow() {
        let now = Date()
        let candidates = [
            ClusterCandidate(id: "a", title: "Apple announces new iPhone lineup today", canonicalURL: "https://x/a", published: now),
            ClusterCandidate(id: "b", title: "Apple announces new iPhone lineup today", canonicalURL: "https://y/b", published: now.addingTimeInterval(-5 * 86_400)),
        ]
        #expect(StoryClusterer.clusters(candidates).isEmpty)
    }
}

@Suite("OPML")
struct OPMLTests {
    @Test func roundTrips() throws {
        let document = OPMLDocument(title: "Tributary", dateCreated: Date(timeIntervalSince1970: 1_788_800_000), outlines: [
            OPMLOutline(text: "Priority", children: [
                OPMLOutline(text: "Daring Fireball", xmlURL: URL(string: "https://daringfireball.net/feeds/main"), htmlURL: URL(string: "https://daringfireball.net/"), attributes: ["tributary:lane": "priority"]),
            ]),
            OPMLOutline(text: "Dezeen", xmlURL: URL(string: "https://www.dezeen.com/feed/"), attributes: ["tributary:lane": "normal", "tributary:cap": "5"]),
        ])
        let data = OPML.render(document)
        let parsed = try OPML.parse(data: data)
        #expect(parsed.title == "Tributary")
        #expect(parsed.outlines.count == 2)
        let feeds = parsed.feeds
        #expect(feeds.count == 2)
        #expect(feeds[0].folderPath == ["Priority"])
        #expect(feeds[0].outline.xmlURL?.absoluteString == "https://daringfireball.net/feeds/main")
        #expect(feeds[0].outline.attributes["tributary:lane"] == "priority")
        #expect(feeds[1].outline.attributes["tributary:cap"] == "5")
    }
}

@Suite("Scheduler")
struct FetchSchedulerTests {
    @Test func adaptsToCadence() {
        let now = Date()
        let hourly = (0..<10).map { now.addingTimeInterval(-Double($0) * 3600) }
        #expect(FetchScheduler.interval(postDates: hourly, isPriority: false, errorCount: 0, now: now) == FetchScheduler.floor)
        let weekly = (0..<6).map { now.addingTimeInterval(-Double($0) * 7 * 86_400) }
        // A quarter of a week is above the daily ceiling, so the ceiling wins.
        #expect(FetchScheduler.interval(postDates: weekly, isPriority: false, errorCount: 0, now: now) == FetchScheduler.ceiling)
        #expect(FetchScheduler.interval(postDates: weekly, isPriority: true, errorCount: 0, now: now) == FetchScheduler.priorityInterval)
        #expect(FetchScheduler.interval(postDates: weekly, isPriority: false, errorCount: 3, now: now) == 2 * 3600)
    }
}
