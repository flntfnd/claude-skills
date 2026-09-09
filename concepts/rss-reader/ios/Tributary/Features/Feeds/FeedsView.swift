import SwiftData
import SwiftUI
import TributaryCore
import UniformTypeIdentifiers

/// The subscription tree: folders, feeds, counts, health, and the hygiene row.
struct FeedsView: View {
    @Environment(\.modelContext) private var context
    @Environment(RefreshCoordinator.self) private var refresher
    @Query(sort: [SortDescriptor(\Feed.sortOrder), SortDescriptor(\Feed.title)]) private var feeds: [Feed]
    @Query(sort: [SortDescriptor(\Folder.sortOrder)]) private var folders: [Folder]
    @State private var showAdd = false
    @State private var showImport = false
    @State private var importPreview: OPMLImporter.Preview?
    @State private var importError: String?
    @State private var showStale = false

    private var stale: [Feed] { feeds.filter { $0.isStale || $0.errorCount >= 3 } }

    var body: some View {
        NavigationStack {
            List {
                if !stale.isEmpty {
                    Button { showStale = true } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "timer").foregroundStyle(DS.Color.Text.secondary)
                            Text("\(stale.count) feed\(stale.count == 1 ? "" : "s") haven’t posted in 90 days or keep failing")
                                .font(.subheadline)
                                .foregroundStyle(DS.Color.Text.secondary)
                            Spacer()
                            Text("Review").font(.subheadline.weight(.semibold)).foregroundStyle(DS.Color.Text.link)
                        }
                        .padding(.horizontal, Spacing.base)
                        .padding(.vertical, Spacing.md)
                        .background(DS.Color.Fill.secondary, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .rowStyle()
                }

                ForEach(folders) { folder in
                    let members = feeds.filter { $0.folder?.id == folder.id }
                    if !members.isEmpty {
                        Section {
                            ForEach(members) { feed in feedRow(feed) }
                        } header: {
                            LaneHeader(title: folder.name, count: members.reduce(0) { $0 + unreadCount($1) })
                        }
                    }
                }
                let unfiled = feeds.filter { $0.folder == nil }
                if !unfiled.isEmpty {
                    Section {
                        ForEach(unfiled) { feed in feedRow(feed) }
                    } header: {
                        LaneHeader(title: "Unfiled", count: unfiled.reduce(0) { $0 + unreadCount($1) })
                    }
                }
                if feeds.isEmpty {
                    ContentUnavailableView {
                        Label("No feeds", systemImage: "dot.radiowaves.up.forward")
                    } description: {
                        Text("Paste any site or feed address, or import an OPML file from another reader.")
                    } actions: {
                        Button("Add feed") { showAdd = true }.buttonStyle(.borderedProminent)
                        Button("Import OPML") { showImport = true }
                    }
                    .rowStyle()
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.horizontal, Spacing.base, for: .scrollContent)
            .contentMargins(.bottom, Spacing.section, for: .scrollContent)
            .background(DS.Color.Background.primary)
            .navigationTitle("Feeds")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Label("Add feed", systemImage: "plus") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Import OPML…", systemImage: "square.and.arrow.down") { showImport = true }
                        Button("Refresh all", systemImage: "arrow.clockwise") { Task { await refresher.refreshAll(reason: .userPull, force: true) } }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddFeedView() }
            .navigationDestination(for: Feed.self) { FeedDetailView(feed: $0) }
            .navigationDestination(isPresented: $showStale) { StaleFeedsView(feeds: stale) }
            .fileImporter(isPresented: $showImport, allowedContentTypes: [UTType("org.opml.opml") ?? .xml, .xml, .plainText]) { result in
                handleImport(result)
            }
            .sheet(item: Binding(get: { importPreview.map(ImportPreviewBox.init) }, set: { importPreview = $0?.preview })) { box in
                ImportPreviewSheet(preview: box.preview) { commit in
                    if commit, let ids = try? OPMLImporter.commit(box.preview, context: context) {
                        Task { for id in ids { await refresher.refresh(feedID: id) } }
                    }
                    importPreview = nil
                }
            }
            .alert("Import failed", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
            .onChange(of: PendingSubscription.shared.url) { _, url in
                if url != nil { showAdd = true }
            }
        }
    }

    private func feedRow(_ feed: Feed) -> some View {
        NavigationLink(value: feed) {
            HStack(spacing: Spacing.md) {
                FaviconView(feed: feed)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(feed.displayTitle)
                        .font(.body)
                        .foregroundStyle(feed.isMuted ? DS.Color.Text.tertiary : DS.Color.Text.primary)
                        .lineLimit(1)
                    if let error = feed.lastError, feed.errorCount > 0 {
                        Text(error).font(.caption).foregroundStyle(DS.Color.Status.error).lineLimit(1)
                    } else if feed.isStale {
                        Text("Nothing new in 90 days").font(.caption).foregroundStyle(DS.Color.Text.tertiary)
                    }
                }
                Spacer()
                if feed.lane == .priority {
                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(DS.Color.Interactive.primary).accessibilityLabel("Priority")
                }
                if feed.isMuted {
                    Image(systemName: "speaker.slash").font(.caption).foregroundStyle(DS.Color.Text.tertiary).accessibilityLabel("Muted")
                }
                let unread = unreadCount(feed)
                if unread > 0 {
                    Text("\(unread)").font(.subheadline).foregroundStyle(DS.Color.Text.tertiary).monospacedDigit()
                }
            }
            .padding(.vertical, Spacing.xs)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { unsubscribe(feed) } label: { Label("Unsubscribe", systemImage: "trash") }
            Button { feed.isMuted.toggle(); try? context.save() } label: { Label(feed.isMuted ? "Unmute" : "Mute", systemImage: feed.isMuted ? "speaker" : "speaker.slash") }
                .tint(DS.Color.Text.secondary)
        }
    }

    private func unreadCount(_ feed: Feed) -> Int {
        (feed.items ?? []).lazy.filter { !$0.isRead }.count
    }

    private func unsubscribe(_ feed: Feed) {
        withAnimation(Motion.automated) {
            context.delete(feed)
            try? context.save()
        }
    }

    private func handleImport(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            guard url.startAccessingSecurityScopedResource() else { throw SubscribeError.invalidInput }
            defer { url.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: url)
            importPreview = try OPMLImporter.preview(data: data, context: context)
        } catch {
            importError = error.localizedDescription
        }
    }
}

private struct ImportPreviewBox: Identifiable {
    let preview: OPMLImporter.Preview
    var id: String { preview.document.title + "\(preview.newFeeds)" }
}

/// "412 feeds in 14 folders. 31 are already subscribed and will be skipped." Then one confirm.
struct ImportPreviewSheet: View {
    let preview: OPMLImporter.Preview
    var finish: (Bool) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("New feeds", value: "\(preview.newFeeds)")
                    LabeledContent("Already subscribed", value: "\(preview.skippedFeeds)")
                    LabeledContent("Folders", value: "\(preview.folders)")
                } footer: {
                    Text("Feeds already in your library are skipped. Nothing is marked read or unread by an import.")
                }
            }
            .navigationTitle(preview.document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { finish(false) } }
                ToolbarItem(placement: .confirmationAction) { Button("Import \(preview.newFeeds)") { finish(true) }.disabled(preview.newFeeds == 0) }
            }
        }
        .presentationDetents([.medium])
    }
}

struct StaleFeedsView: View {
    @Environment(\.modelContext) private var context
    var feeds: [Feed]

    var body: some View {
        List {
            ForEach(feeds) { feed in
                HStack {
                    FaviconView(feed: feed)
                    VStack(alignment: .leading) {
                        Text(feed.displayTitle).font(.body)
                        Text(feed.lastError ?? "Last post \(feed.lastPostedAt?.formatted(date: .abbreviated, time: .omitted) ?? "unknown")")
                            .font(.caption).foregroundStyle(DS.Color.Text.tertiary)
                    }
                    Spacer()
                    Button("Unsubscribe", role: .destructive) {
                        context.delete(feed)
                        try? context.save()
                    }
                    .font(.subheadline)
                }
            }
        }
        .navigationTitle("Review feeds")
    }
}
