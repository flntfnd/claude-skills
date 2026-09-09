import SwiftData
import SwiftUI

/// Full-text search over everything received. Local mode searches everything cached, which is
/// everything since install. Operators: `feed:`, `author:`, `saved`, `unread`.
struct SearchView: View {
    @Environment(\.modelContext) private var context
    @State private var query = ""
    @State private var results: [Item] = []
    @State private var isSearching = false
    @AppStorage("search.recent") private var recentRaw = ""

    private var recent: [String] { recentRaw.split(separator: "\n").map(String.init).filter { !$0.isEmpty } }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    if !recent.isEmpty {
                        Section("Recent") {
                            ForEach(recent, id: \.self) { term in
                                Button {
                                    query = term
                                } label: {
                                    Label(term, systemImage: "clock").foregroundStyle(DS.Color.Text.primary)
                                }
                            }
                        }
                    }
                    Section("Tips") {
                        Text("feed:dezeen stone").font(.footnote).foregroundStyle(DS.Color.Text.secondary)
                        Text("author:gruber carplay").font(.footnote).foregroundStyle(DS.Color.Text.secondary)
                        Text("saved liquid glass").font(.footnote).foregroundStyle(DS.Color.Text.secondary)
                    }
                } else if isSearching {
                    ProgressView().rowStyle()
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query).rowStyle()
                } else {
                    LaneHeader(title: "Results", count: results.count).rowStyle()
                    ForEach(results) { item in
                        NavigationLink(value: item) { ArticleCard(item: item, size: .standard) }
                            .rowStyle()
                            .contextMenu { ItemContextMenu(item: item) }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.horizontal, Spacing.base, for: .scrollContent)
            .background(DS.Color.Background.primary)
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Everything you’ve received")
            .onSubmit(of: .search) { remember(query) }
            .task(id: query) {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                await search()
            }
            .navigationDestination(for: Item.self) { ReaderView(item: $0) }
        }
    }

    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { results = []; return }
        isSearching = true
        defer { isSearching = false }
        let parsed = SearchQuery(trimmed)
        let needle = parsed.text
        var descriptor: FetchDescriptor<Item>
        if needle.isEmpty {
            descriptor = FetchDescriptor<Item>()
        } else {
            descriptor = FetchDescriptor<Item>(predicate: #Predicate { item in
                item.title.localizedStandardContains(needle) || item.contentText.localizedStandardContains(needle)
            })
        }
        descriptor.sortBy = [SortDescriptor(\Item.publishedAt, order: .reverse)]
        descriptor.fetchLimit = 400
        let fetched = (try? context.fetch(descriptor)) ?? []
        results = fetched.filter { item in
            if parsed.savedOnly, !item.isSaved { return false }
            if parsed.unreadOnly, item.isRead { return false }
            if let feed = parsed.feed, !(item.feed?.displayTitle.localizedCaseInsensitiveContains(feed) ?? false) { return false }
            if let author = parsed.author, !(item.author?.localizedCaseInsensitiveContains(author) ?? false) { return false }
            return true
        }
    }

    private func remember(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var list = recent.filter { $0 != trimmed }
        list.insert(trimmed, at: 0)
        recentRaw = list.prefix(8).joined(separator: "\n")
    }
}

/// `feed:` and `author:` scope a query; `saved` and `unread` filter it.
struct SearchQuery {
    var text = ""
    var feed: String?
    var author: String?
    var savedOnly = false
    var unreadOnly = false

    init(_ raw: String) {
        var words: [String] = []
        for token in raw.split(separator: " ") {
            let lowered = token.lowercased()
            if lowered.hasPrefix("feed:") { feed = String(token.dropFirst(5)) }
            else if lowered.hasPrefix("author:") { author = String(token.dropFirst(7)) }
            else if lowered == "saved" { savedOnly = true }
            else if lowered == "unread" { unreadOnly = true }
            else { words.append(String(token)) }
        }
        text = words.joined(separator: " ")
    }
}
