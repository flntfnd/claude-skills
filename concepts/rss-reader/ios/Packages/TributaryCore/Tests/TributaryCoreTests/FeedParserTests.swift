import Foundation
import Testing
@testable import TributaryCore

@Suite("Feed parsing")
struct FeedParserTests {
    static let rss = """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:atom="http://www.w3.org/2005/Atom">
    <channel>
      <title>Daring Fireball</title>
      <link>https://daringfireball.net/</link>
      <description>By John Gruber</description>
      <atom:link rel="hub" href="https://pubsubhubbub.appspot.com/"/>
      <image><url>https://daringfireball.net/graphics/logos/df.png</url><title>DF</title></image>
      <item>
        <title>It&#8217;s True That I Stole Your Lighter, and It&#8217;s Also True That I Lost the Map</title>
        <link>https://daringfireball.net/2026/09/lake_america?utm_source=rss</link>
        <guid isPermaLink="false">tag:daringfireball.net,2026:/2026/09/lake_america</guid>
        <pubDate>Mon, 07 Sep 2026 14:12:00 -0400</pubDate>
        <dc:creator>John Gruber</dc:creator>
        <description><![CDATA[<p>Last week both Google and Apple updated their maps.</p>]]></description>
        <content:encoded><![CDATA[<p>Last week both Google and Apple updated their maps to accommodate the USGS change.</p><p>Here are the names you now see:</p><ul><li>United States: &#8220;Lake America&#8221;</li><li>Canada: &#8220;Lake Ontario&#8221;</li></ul><p><img src="/graphics/2026/map.png" alt="Map"></p>]]></content:encoded>
      </item>
      <item>
        <title>Second Post</title>
        <link>https://daringfireball.net/2026/09/second</link>
        <pubDate>Sun, 06 Sep 2026 10:00:00 -0400</pubDate>
        <enclosure url="https://daringfireball.net/audio/second.mp3" type="audio/mpeg" length="12345"/>
        <description>Short.</description>
      </item>
    </channel>
    </rss>
    """

    static let atom = """
    <?xml version="1.0" encoding="utf-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <title>Six Colors</title>
      <link rel="alternate" type="text/html" href="https://sixcolors.com/"/>
      <link rel="self" href="https://sixcolors.com/feed/"/>
      <icon>https://sixcolors.com/favicon.png</icon>
      <updated>2026-09-04T18:00:00Z</updated>
      <entry>
        <title>This Week in Apple: Counting Apple CEOs</title>
        <link rel="alternate" href="https://sixcolors.com/post/2026/09/counting-ceos/"/>
        <id>https://sixcolors.com/post/2026/09/counting-ceos/</id>
        <published>2026-09-04T17:30:00.123Z</published>
        <updated>2026-09-04T18:00:00Z</updated>
        <author><name>John Moltz</name></author>
        <category term="Apple"/>
        <summary type="html">&lt;p&gt;A short one.&lt;/p&gt;</summary>
        <content type="html">&lt;p&gt;Apple has had a handful of CEOs.&lt;/p&gt;&lt;blockquote&gt;&lt;p&gt;Quote here.&lt;/p&gt;&lt;/blockquote&gt;</content>
      </entry>
    </feed>
    """

    static let json = """
    {
      "version": "https://jsonfeed.org/version/1.1",
      "title": "Craig Mod",
      "home_page_url": "https://craigmod.com/",
      "feed_url": "https://craigmod.com/index.json",
      "icon": "https://craigmod.com/icon.png",
      "items": [
        {
          "id": 8812,
          "url": "https://craigmod.com/ridgeline/223/",
          "title": "Walking the Length of Manhattan",
          "content_html": "<p>Back in May the plan was five or six days of long walks.</p><p>A moment of reflection led somewhere else.</p>",
          "date_published": "2026-08-21T09:00:00-04:00",
          "authors": [{"name": "Craig Mod"}],
          "tags": ["walking", "ridgeline"],
          "image": "https://craigmod.com/images/manhattan.jpg"
        }
      ]
    }
    """

    @Test func parsesRSSWithNamespaces() throws {
        let feed = try FeedParser.parse(data: Data(Self.rss.utf8), sourceURL: URL(string: "https://daringfireball.net/feeds/main"))
        #expect(feed.format == .rss)
        #expect(feed.title == "Daring Fireball")
        #expect(feed.siteURL?.absoluteString == "https://daringfireball.net/")
        #expect(feed.hubURL?.absoluteString == "https://pubsubhubbub.appspot.com/")
        #expect(feed.iconURL?.absoluteString == "https://daringfireball.net/graphics/logos/df.png")
        #expect(feed.items.count == 2)

        let first = feed.items[0]
        #expect(first.title == "It’s True That I Stole Your Lighter, and It’s Also True That I Lost the Map")
        #expect(first.guid == "tag:daringfireball.net,2026:/2026/09/lake_america")
        #expect(first.author == "John Gruber")
        #expect(first.contentHTML?.contains("<ul>") == true)
        #expect(first.imageURL?.absoluteString == "https://daringfireball.net/graphics/2026/map.png")
        let published = try #require(first.published)
        // Mon, 07 Sep 2026 14:12:00 -0400 is 18:12:00 UTC.
        #expect(Int(published.timeIntervalSince1970) == 1_788_804_720)

        let second = feed.items[1]
        #expect(second.guid == "https://daringfireball.net/2026/09/second")
        #expect(second.enclosures.first?.isAudio == true)
        #expect(second.looksTruncated)
    }

    @Test func parsesAtom() throws {
        let feed = try FeedParser.parse(data: Data(Self.atom.utf8), sourceURL: nil)
        #expect(feed.format == .atom)
        #expect(feed.title == "Six Colors")
        #expect(feed.siteURL?.absoluteString == "https://sixcolors.com/")
        #expect(feed.iconURL?.absoluteString == "https://sixcolors.com/favicon.png")
        let entry = try #require(feed.items.first)
        #expect(entry.url?.absoluteString == "https://sixcolors.com/post/2026/09/counting-ceos/")
        #expect(entry.author == "John Moltz")
        #expect(entry.categories == ["Apple"])
        #expect(entry.contentHTML?.contains("<blockquote>") == true)
        #expect(entry.summaryHTML == "<p>A short one.</p>")
        #expect(entry.published != nil)
        #expect(entry.updated != nil)
    }

    @Test func parsesJSONFeedWithNumericID() throws {
        let feed = try FeedParser.parse(data: Data(Self.json.utf8), sourceURL: nil)
        #expect(feed.format == .jsonFeed)
        #expect(feed.title == "Craig Mod")
        let item = try #require(feed.items.first)
        #expect(item.guid == "8812")
        #expect(item.author == "Craig Mod")
        #expect(item.categories == ["walking", "ridgeline"])
        #expect(item.imageURL?.absoluteString == "https://craigmod.com/images/manhattan.jpg")
        #expect(item.published != nil)
    }

    @Test func rejectsEmptyAndUnknown() {
        #expect(throws: FeedParserError.empty) { try FeedParser.parse(data: Data("   \n".utf8)) }
        #expect(throws: (any Error).self) { try FeedParser.parse(data: Data("<html><body>not a feed</body></html>".utf8)) }
    }

    @Test func cadenceAndFullText() throws {
        let feed = try FeedParser.parse(data: Data(Self.rss.utf8))
        #expect(feed.postsPerWeek > 5)
        // Both fixture items carry teasers, so the feed reads as stubs that need extraction.
        #expect(feed.fullTextRatio == 0)
        #expect(feed.items.allSatisfy(\.looksTruncated))
    }
}

@Suite("Dates")
struct FeedDateTests {
    @Test func parsesCommonFormats() {
        let dates = FeedDates()
        #expect(dates.parse("Mon, 07 Sep 2026 14:12:00 -0400") != nil)
        #expect(dates.parse("Mon, 07 Sep 2026 14:12:00 GMT") != nil)
        #expect(dates.parse("2026-09-07T18:12:00Z") != nil)
        #expect(dates.parse("2026-09-07T18:12:00.500+02:00") != nil)
        #expect(dates.parse("2026-09-07") != nil)
        #expect(dates.parse("yesterday") == nil)
    }
}
