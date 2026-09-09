import SwiftData
import SwiftUI
import TributaryCore

/// Paste anything, see what it is before you follow it: last items, posts per week,
/// full text or stubs, and which lane it lands in.
struct AddFeedView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(RefreshCoordinator.self) private var refresher
    @Query(sort: [SortDescriptor(\Folder.sortOrder)]) private var folders: [Folder]
    @State private var input = ""
    @State private var previews: [FeedPreview] = []
    @State private var selected: FeedPreview?
    @State private var lane: Lane = .normal
    @State private var folder: Folder?
    @State private var isSearching = false
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Site or feed address", text: $input)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .focused($focused)
                        .onSubmit { Task { await discover() } }
                    if isSearching {
                        HStack { ProgressView(); Text("Looking for feeds…").foregroundStyle(DS.Color.Text.secondary) }
                    }
                    if let error {
                        Text(error).font(.footnote).foregroundStyle(DS.Color.Status.error)
                    }
                }

                if previews.count > 1 {
                    Section("Feeds on this site") {
                        ForEach(previews) { preview in
                            Button {
                                selected = preview
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(preview.parsed.title).foregroundStyle(DS.Color.Text.primary)
                                        Text(preview.url.absoluteString).font(.caption).foregroundStyle(DS.Color.Text.tertiary).lineLimit(1)
                                    }
                                    Spacer()
                                    if selected?.id == preview.id { Image(systemName: "checkmark").foregroundStyle(DS.Color.Interactive.primary) }
                                }
                            }
                        }
                    }
                }

                if let preview = selected {
                    Section {
                        LabeledContent("Posts per week", value: preview.postsPerWeek.formatted(.number.precision(.fractionLength(0...1))))
                        LabeledContent("Full text", value: preview.fullTextRatio >= 0.7 ? "Yes" : preview.fullTextRatio > 0.2 ? "Sometimes" : "Stubs, extracted on open")
                        if let latest = preview.latest {
                            LabeledContent("Last post", value: latest.formatted(.relative(presentation: .named)))
                        }
                        LabeledContent("Format", value: preview.parsed.format.rawValue.uppercased())
                    } header: {
                        Text(preview.parsed.title)
                    }

                    Section("Recent items") {
                        ForEach(preview.parsed.items.prefix(6), id: \.guid) { item in
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(item.title).font(.subheadline).lineLimit(2)
                                if let date = item.published {
                                    Text(date, format: .relative(presentation: .named)).font(.caption).foregroundStyle(DS.Color.Text.tertiary)
                                }
                            }
                        }
                    }

                    Section {
                        Picker("Lane", selection: $lane) {
                            ForEach(Lane.allCases) { Text($0.title).tag($0) }
                        }
                        Picker("Folder", selection: $folder) {
                            Text("None").tag(Folder?.none)
                            ForEach(folders) { Text($0.name).tag(Folder?.some($0)) }
                        }
                    } footer: {
                        Text(lane.explanation)
                    }
                }
            }
            .navigationTitle("Add feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if selected == nil {
                        Button("Find") { Task { await discover() } }.disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                    } else {
                        Button("Subscribe") { subscribe() }
                    }
                }
            }
            .task {
                if let pending = PendingSubscription.shared.url {
                    input = pending.absoluteString
                    PendingSubscription.shared.url = nil
                    await discover()
                } else {
                    focused = true
                }
            }
        }
    }

    private func discover() async {
        error = nil
        previews = []
        selected = nil
        isSearching = true
        defer { isSearching = false }
        do {
            previews = try await FeedSubscriber.discover(input: input)
            selected = previews.first
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func subscribe() {
        guard let preview = selected else { return }
        do {
            _ = try FeedSubscriber.subscribe(preview, lane: lane, folder: folder, in: context)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// Per-feed settings and its own item list.
struct FeedDetailView: View {
    @Bindable var feed: Feed
    @Environment(\.modelContext) private var context
    @Environment(RefreshCoordinator.self) private var refresher

    private var items: [Item] {
        (feed.items ?? []).sorted { $0.sortDate > $1.sortDate }
    }

    var body: some View {
        List {
            Section {
                Picker("Lane", selection: $feed.lane) {
                    ForEach(Lane.allCases) { Text($0.title).tag($0) }
                }
                Stepper(feed.dailyCap == 0 ? "No daily cap" : "At most \(feed.dailyCap) a day", value: $feed.dailyCap, in: 0...50)
                Toggle("Muted", isOn: $feed.isMuted)
                TextField("Custom title", text: Binding(get: { feed.customTitle ?? "" }, set: { feed.customTitle = $0.isEmpty ? nil : $0 }))
            } footer: {
                Text(feed.lane.explanation)
            }
            Section("Health") {
                LabeledContent("Feed", value: feed.url).lineLimit(1)
                LabeledContent("Last fetched", value: feed.lastFetchedAt?.formatted(.relative(presentation: .named)) ?? "Never")
                LabeledContent("Last post", value: feed.lastPostedAt?.formatted(.relative(presentation: .named)) ?? "Unknown")
                LabeledContent("Checks every", value: Duration.seconds(feed.fetchIntervalSeconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))
                if let error = feed.lastError { LabeledContent("Error", value: error).foregroundStyle(DS.Color.Status.error) }
            }
            Section("Items") {
                ForEach(items.prefix(200)) { item in
                    NavigationLink(value: item) {
                        HStack(spacing: Spacing.sm) {
                            if !item.isRead { UnreadDot() }
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(item.title).font(.body).lineLimit(2).foregroundStyle(item.isRead ? DS.Color.Text.secondary : DS.Color.Text.primary)
                                Text(item.sortDate, format: .relative(presentation: .named)).font(.caption).foregroundStyle(DS.Color.Text.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(feed.displayTitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await refresher.refresh(feedID: feed.id) } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
            }
        }
        .navigationDestination(for: Item.self) { ReaderView(item: $0) }
        .onChange(of: feed.laneRaw) { _, _ in try? context.save() }
        .onChange(of: feed.dailyCap) { _, _ in try? context.save() }
        .onChange(of: feed.isMuted) { _, _ in try? context.save() }
    }
}
