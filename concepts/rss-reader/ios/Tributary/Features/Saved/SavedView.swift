import SwiftData
import SwiftUI

enum SavedLayout: String, CaseIterable, Identifiable {
    case grid, list, stacks
    var id: Self { self }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .grid: "square.grid.2x2"
        case .list: "list.bullet"
        case .stacks: "square.stack.3d.up"
        }
    }
}

/// Saved is the read-later list for anything. Grid shows covers at natural proportions
/// with no text at rest; list is the familiar rows; stacks are unnamed groups.
struct SavedView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Item> { $0.isSaved }, sort: [SortDescriptor(\Item.savedAt, order: .reverse)]) private var saved: [Item]
    @Query(sort: [SortDescriptor(\ItemStack.createdAt, order: .reverse)]) private var stacks: [ItemStack]
    @AppStorage("saved.layout") private var layoutRaw = SavedLayout.grid.rawValue
    @State private var showUpNext = false

    private var layout: SavedLayout { SavedLayout(rawValue: layoutRaw) ?? .grid }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Picker("Layout", selection: $layoutRaw) {
                        ForEach(SavedLayout.allCases) { Label($0.title, systemImage: $0.symbol).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)

                    if saved.isEmpty {
                        ContentUnavailableView("Nothing saved yet", systemImage: "bookmark", description: Text("Swipe a card to save it, or share a link to Tributary from any app."))
                            .padding(.top, Spacing.section)
                    } else {
                        switch layout {
                        case .grid: grid
                        case .list: list
                        case .stacks: stackList
                        }
                    }
                }
                .padding(.horizontal, Spacing.base)
                .padding(.bottom, Spacing.section)
            }
            .background(DS.Color.Background.primary)
            .navigationTitle("Saved")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showUpNext = true } label: { Label("Up Next", systemImage: "text.line.first.and.arrowtriangle.forward") }
                }
            }
            .navigationDestination(for: Item.self) { ReaderView(item: $0) }
            .navigationDestination(isPresented: $showUpNext) { UpNextView() }
        }
    }

    /// Two columns, each a vertical stack, so tiles keep their own proportions.
    private var grid: some View {
        let columns = distribute(saved)
        return HStack(alignment: .top, spacing: Spacing.sm) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(column) { item in
                        NavigationLink(value: item) { GridTile(item: item) }
                            .buttonStyle(.plain)
                            .contextMenu { ItemContextMenu(item: item) }
                    }
                }
            }
        }
    }

    private func distribute(_ items: [Item]) -> [[Item]] {
        var left: [Item] = [], right: [Item] = []
        var leftHeight = 0.0, rightHeight = 0.0
        for item in items {
            let height = item.cover == nil ? 1.0 : 1.3
            if leftHeight <= rightHeight { left.append(item); leftHeight += height } else { right.append(item); rightHeight += height }
        }
        return [left, right]
    }

    private var list: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(saved) { item in
                NavigationLink(value: item) { ArticleCard(item: item, size: .standard) }
                    .buttonStyle(.plain)
                    .contextMenu { ItemContextMenu(item: item) }
            }
        }
    }

    private var stackList: some View {
        LazyVStack(spacing: Spacing.sm) {
            if stacks.filter({ !$0.isUpNext }).isEmpty {
                Text("Stacks are small groups of saved articles. Long-press an article and choose “Stack with…” to start one.")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.Text.secondary)
                    .padding(.top, Spacing.base)
            }
            ForEach(stacks.filter { !$0.isUpNext }) { stack in
                NavigationLink(value: stack) {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "square.stack.3d.up").foregroundStyle(DS.Color.Text.secondary)
                        Text(stack.displayName).font(.body).foregroundStyle(DS.Color.Text.primary)
                        Spacer()
                        Text("\(stack.itemIDs.count)").font(.subheadline).foregroundStyle(DS.Color.Text.tertiary)
                        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(DS.Color.Text.tertiary)
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.vertical, Spacing.md)
                    .groupedSurface()
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: ItemStack.self) { StackView(stack: $0) }
    }
}

/// Cover at its natural proportion, nothing else at rest. Title and source on long press.
struct GridTile: View {
    let item: Item

    var body: some View {
        Group {
            if let cover = item.cover {
                AsyncImage(url: cover) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
        .accessibilityLabel(item.title)
    }

    private var placeholder: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).fill(DS.Color.Fill.default)
            Text(item.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineLimit(4)
                .padding(Spacing.md)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct StackView: View {
    @Bindable var stack: ItemStack
    @Environment(\.modelContext) private var context
    @Query private var allItems: [Item]

    private var items: [Item] {
        stack.itemIDs.compactMap { id in allItems.first { $0.id == id } }
    }

    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink(value: item) { ArticleCard(item: item, size: .standard) }.rowStyle()
            }
            .onDelete { offsets in
                stack.itemIDs.remove(atOffsets: offsets)
                try? context.save()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.horizontal, Spacing.base, for: .scrollContent)
        .background(DS.Color.Background.primary)
        .navigationTitle(stack.displayName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Dissolve", role: .destructive) {
                    context.delete(stack)
                    try? context.save()
                }
            }
        }
        .navigationDestination(for: Item.self) { ReaderView(item: $0) }
    }
}

/// Up Next is the one ordered stack: a playlist for articles with the total time remaining.
///
/// TODO(iOS 27): replace `.onMove` with the new reorderable container
/// (`.reorderable()` on the ForEach plus `.reorderContainer(for:)` on the container) once the
/// exact signatures are verified against the Xcode 27 SDK. `.onMove` in a List is the iOS 26 form.
struct UpNextView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<ItemStack> { $0.isUpNext }) private var queues: [ItemStack]
    @Query private var allItems: [Item]

    private var queue: ItemStack? { queues.first }
    private var items: [Item] { queue?.itemIDs.compactMap { id in allItems.first { $0.id == id } } ?? [] }
    private var minutes: Int { items.reduce(0) { $0 + $1.readingMinutes } }

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView("Up Next is empty", systemImage: "text.line.first.and.arrowtriangle.forward", description: Text("Add articles from a card’s menu. They open one after another."))
                    .rowStyle()
            } else {
                Text("\(items.count) articles · \(minutes) min")
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .rowStyle()
            }
            ForEach(items) { item in
                NavigationLink(value: item) { ArticleCard(item: item, size: .standard) }.rowStyle()
            }
            .onMove { offsets, destination in
                queue?.itemIDs.move(fromOffsets: offsets, toOffset: destination)
                try? context.save()
            }
            .onDelete { offsets in
                queue?.itemIDs.remove(atOffsets: offsets)
                try? context.save()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.horizontal, Spacing.base, for: .scrollContent)
        .background(DS.Color.Background.primary)
        .navigationTitle("Up Next")
        .toolbar { EditButton() }
        .navigationDestination(for: Item.self) { ReaderView(item: $0) }
    }
}
