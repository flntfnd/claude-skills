import AppIntents
import SwiftData
import TributaryCore

/// "Save this" from Siri, Shortcuts, and Spotlight. Extracts the page on device and files it
/// in Saved with full offline text. This is how Saved becomes the read-later list for anything.
struct SaveLinkIntent: AppIntent {
    static let title: LocalizedStringResource = "Save Link to Tributary"
    static let description = IntentDescription("Saves a web page to Tributary with its full text for offline reading.")
    static let openAppWhenRun = false

    @Parameter(title: "Link")
    var url: URL

    static var parameterSummary: some ParameterSummary {
        Summary("Save \(\.$url) to Tributary")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try SharedContainer.container()
        let context = container.mainContext
        let canonical = CanonicalURL.normalize(url)
        let existing = try context.fetch(FetchDescriptor<Item>(predicate: #Predicate { $0.canonicalURL == canonical }))
        let item: Item
        if let found = existing.first {
            item = found
        } else {
            item = Item(guid: canonical, title: url.host() ?? url.absoluteString)
            item.url = url.absoluteString
            item.canonicalURL = canonical
            item.publishedAt = Date()
            context.insert(item)
        }
        item.isSaved = true
        item.savedAt = Date()
        try context.save()

        if let html = try? await FeedFetcher.fetchPage(url) {
            let article = ArticleExtractor.extract(html: html, baseURL: url)
            if let title = article.title, !title.isEmpty { item.title = title }
            item.author = item.author ?? article.author
            item.extractedBlocks = article.blocks
            item.contentText = article.plainText
            item.wordCount = article.wordCount
            item.imageURL = item.imageURL ?? article.leadImageURL?.absoluteString
            try context.save()
        }
        return .result(dialog: "Saved “\(item.title)” to Tributary.")
    }
}

struct RefreshFeedsIntent: AppIntent {
    static let title: LocalizedStringResource = "Refresh Tributary"
    static let description = IntentDescription("Checks every feed for new articles.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try SharedContainer.container()
        let coordinator = RefreshCoordinator(container: container)
        await coordinator.refreshAll(reason: .background, force: true)
        let report = coordinator.lastReport
        return .result(dialog: "\(report?.newItems ?? 0) new articles.")
    }
}

struct TributaryShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SaveLinkIntent(),
            phrases: ["Save this to \(.applicationName)", "Save link in \(.applicationName)"],
            shortTitle: "Save Link",
            systemImageName: "bookmark"
        )
        AppShortcut(
            intent: RefreshFeedsIntent(),
            phrases: ["Refresh \(.applicationName)", "Check my feeds in \(.applicationName)"],
            shortTitle: "Refresh Feeds",
            systemImageName: "arrow.clockwise"
        )
    }
}

/// Intents can run without the app's scene. When the app is running they reuse its container;
/// otherwise they open the same store themselves.
enum SharedContainer {
    @MainActor static var live: ModelContainer?

    @MainActor
    static func container() throws -> ModelContainer {
        if let live { return live }
        let schema = Schema([Feed.self, Folder.self, Item.self, Highlight.self, ItemStack.self])
        let cloud: ModelConfiguration.CloudKitDatabase = AppSettings.shared.iCloudSyncEnabled ? .automatic : .none
        let configuration = ModelConfiguration("Tributary", schema: schema, cloudKitDatabase: cloud)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
