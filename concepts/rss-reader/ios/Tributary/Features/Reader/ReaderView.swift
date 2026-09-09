import SwiftData
import SwiftUI
import TributaryCore
#if canImport(UIKit)
import UIKit
#endif

/// The reading surface. Structured blocks, a floating Liquid Glass action bar, typography that
/// is the reader's, read position that follows you, listen, and honest paywall handling.
struct ReaderView: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(RefreshCoordinator.self) private var refresher
    @Environment(\.openURL) private var openURL
    @State private var blocks: [ContentBlock] = []
    @State private var isExtracting = false
    @State private var extractionFailed = false
    @State private var showTypography = false
    @State private var summary: String?
    @State private var isSummarizing = false
    @State private var speech = SpeechReader()
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    private var fontScale: CGFloat { scale * settings.readerFontScale }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                if item.updateCount > 0 { updatedChip }
                if let summary { summaryCard(summary) }
                if isExtracting { extractingRow }
                if extractionFailed || (blocks.isEmpty && item.looksTruncated && !isExtracting) { paywallNotice }
                ArticleBodyView(blocks: blocks, fontScale: fontScale, face: settings.readerFace, speakingIndex: speech.currentIndex)
                if let link = item.link, blocks.isEmpty, !isExtracting {
                    Link("Open the original", destination: link)
                }
            }
            .frame(maxWidth: Size.readerMeasure, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.base)
            .padding(.top, Spacing.base)
            .padding(.bottom, Spacing.section * 2)
        }
        .background(readerBackground)
        .preferredColorScheme(colorScheme)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showTypography = true } label: { Label("Typography", systemImage: "textformat.size") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if settings.summariesEnabled, Summarizer.isAvailable {
                        Button("Summarize on device", systemImage: "text.quote") { summarize() }.disabled(isSummarizing)
                    }
                    if let link = item.link {
                        Button("Open in Safari", systemImage: "safari") { openURL(link) }
                        ShareLink(item: link) { Label("Share", systemImage: "square.and.arrow.up") }
                    }
                    Button("Add to Up Next", systemImage: "text.line.first.and.arrowtriangle.forward") { ItemActions.addToUpNext(item, in: context) }
                    Button(item.isRead ? "Mark unread" : "Mark read", systemImage: "circle") { ItemActions.toggleRead(item, in: context) }
                    if item.link != nil {
                        Button("Extract full article", systemImage: "doc.text") { Task { await extract(force: true) } }
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) { actionBar }
        .sheet(isPresented: $showTypography) { TypographySheet().presentationDetents([.medium]) }
        .task(id: item.id) { await load() }
        .onAppear {
            item.lastOpenedAt = Date()
            ItemActions.markRead(item)
            try? context.save()
        }
        .onDisappear { speech.stop() }
        .userActivity("com.flntfnd.tributary.reading", isActive: item.link != nil) { activity in
            activity.title = item.title
            activity.webpageURL = item.link
            activity.isEligibleForHandoff = true
        }
    }

    // MARK: Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(item.sourceTitle.uppercased())
                .font(.system(size: ReaderType.metaSize * fontScale, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(DS.Color.Text.link)
            Text(item.title)
                .font(ReaderType.font(size: ReaderType.displaySize * fontScale, weight: .bold, face: settings.readerFace))
                .foregroundStyle(DS.Color.Text.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text(meta)
                .font(.system(size: ReaderType.metaSize * fontScale, weight: .medium))
                .foregroundStyle(DS.Color.Text.tertiary)
            Divider()
        }
    }

    private var meta: String {
        var parts: [String] = []
        if let author = item.author, !author.isEmpty { parts.append(author) }
        if let date = item.publishedAt { parts.append(date.formatted(date: .complete, time: .omitted)) }
        parts.append("\(item.readingMinutes) min")
        return parts.joined(separator: " · ")
    }

    private var updatedChip: some View {
        Label("Updated · \(item.updateCount) change\(item.updateCount == 1 ? "" : "s") since you read", systemImage: "arrow.clockwise")
            .font(.caption)
            .foregroundStyle(DS.Color.Text.secondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(DS.Color.Fill.default, in: Capsule())
    }

    private func summaryCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("On-device summary", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Color.Text.link)
            Text(text)
                .font(ReaderType.font(size: ReaderType.captionSize * fontScale + 2, face: settings.readerFace))
                .foregroundStyle(DS.Color.Text.secondary)
        }
        .padding(Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .groupedSurface()
    }

    private var extractingRow: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
            Text("Fetching the full article…").font(.footnote).foregroundStyle(DS.Color.Text.secondary)
        }
    }

    /// Never circumvent a paywall. Say so, and hand off to the browser where the user's
    /// subscription cookies live.
    private var paywallNotice: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "lock").foregroundStyle(DS.Color.Text.secondary)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Only a preview came through").font(.subheadline.weight(.semibold)).foregroundStyle(DS.Color.Text.primary)
                Text("This site meters articles or blocks extraction. Open it in Safari to read with your subscription.")
                    .font(.footnote).foregroundStyle(DS.Color.Text.secondary)
            }
            Spacer()
            if let link = item.link {
                Button("Open") { openURL(link) }.font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
        .background(DS.Color.Fill.default, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private var actionBar: some View {
        GlassEffectContainer(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                GlassIconButton(systemImage: "checkmark", label: item.isRead ? "Mark unread" : "Mark read", isActive: item.isRead) {
                    ItemActions.toggleRead(item, in: context)
                }
                GlassIconButton(systemImage: "bookmark", label: item.isSaved ? "Remove from Saved" : "Save", isActive: item.isSaved) {
                    ItemActions.toggleSaved(item, in: context)
                }
                GlassIconButton(systemImage: speech.isSpeaking ? (speech.isPaused ? "play" : "pause") : "waveform", label: "Listen", isActive: speech.isSpeaking) {
                    if speech.isSpeaking { speech.togglePause() } else { speech.speak(paragraphs) }
                }
                if let link = item.link {
                    ShareLink(item: link, subject: Text(item.title)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.medium))
                            .foregroundStyle(DS.Color.Text.primary)
                            .frame(width: Size.touchTarget, height: Size.touchTarget)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                }
            }
            .padding(Spacing.sm)
            .glassEffect(.regular, in: Capsule())
        }
        .padding(.bottom, Spacing.sm)
    }

    private var paragraphs: [String] {
        [item.title] + blocks.map(\.plainText).filter { !$0.isEmpty }
    }

    private var readerBackground: Color {
        switch settings.readerTheme {
        case .sepia: DS.Color.Background.sepia
        case .black: .black
        default: DS.Color.Background.reader
        }
    }

    private var colorScheme: ColorScheme? {
        switch settings.readerTheme {
        case .light, .sepia: .light
        case .dark, .black: .dark
        case .system: nil
        }
    }

    // MARK: Loading

    private func load() async {
        if let stored = item.extractedBlocks, !stored.isEmpty {
            blocks = stored
            return
        }
        if let html = item.bodyHTML {
            blocks = HTMLBlocks.blocks(from: html, baseURL: item.link)
        }
        if item.looksTruncated, settings.readerViewByDefault, item.link != nil {
            await extract(force: false)
        }
    }

    private func extract(force: Bool) async {
        guard !isExtracting else { return }
        isExtracting = true
        extractionFailed = false
        defer { isExtracting = false }
        let ok = await refresher.extract(itemID: item.id)
        if ok, let stored = item.extractedBlocks, !stored.isEmpty, (force || HTMLBlocks.plainText(of: stored).count > HTMLBlocks.plainText(of: blocks).count) {
            withAnimation(Motion.automated) { blocks = stored }
        } else if !ok {
            extractionFailed = blocks.isEmpty || item.looksTruncated
        }
    }

    private func summarize() {
        isSummarizing = true
        let title = item.title
        let text = HTMLBlocks.plainText(of: blocks).isEmpty ? item.contentText : HTMLBlocks.plainText(of: blocks)
        Task {
            defer { isSummarizing = false }
            summary = (try? await Summarizer.shared.summarize(title: title, text: text)) ?? "The on-device model couldn’t summarize this one."
        }
    }
}

/// Renders blocks with the reader scale. Headings, paragraphs, quotes, figures with captions,
/// code that scrolls instead of wrapping, and lists. The paragraph being read aloud is tinted.
struct ArticleBodyView: View {
    var blocks: [ContentBlock]
    var fontScale: CGFloat
    var face: ReaderFace
    var speakingIndex: Int?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: Spacing.lg) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                render(block)
                    .background(speakingIndex == index + 1 ? DS.Color.Interactive.primarySubtle : Color.clear, in: RoundedRectangle(cornerRadius: Radius.xs))
            }
        }
    }

    @ViewBuilder
    private func render(_ block: ContentBlock) -> some View {
        switch block {
        case let .heading(level, text):
            Text(text.attributed)
                .font(ReaderType.font(size: headingSize(level) * fontScale, weight: level <= 1 ? .bold : .semibold, face: face))
                .foregroundStyle(DS.Color.Text.primary)
                .padding(.top, Spacing.sm)
        case let .paragraph(text):
            Text(text.attributed)
                .font(ReaderType.font(size: ReaderType.bodySize * fontScale, face: face))
                .lineSpacing((ReaderType.bodyLeading - ReaderType.bodySize) * fontScale * 0.5)
                .foregroundStyle(DS.Color.Text.primary)
        case let .quote(text):
            HStack(alignment: .top, spacing: Spacing.base) {
                RoundedRectangle(cornerRadius: 2).fill(DS.Color.Interactive.primary).frame(width: 3)
                Text(text.attributed)
                    .font(ReaderType.font(size: ReaderType.leadSize * fontScale, face: face).italic())
                    .foregroundStyle(DS.Color.Text.secondary)
            }
        case let .image(url, alt, caption):
            VStack(alignment: .leading, spacing: Spacing.sm) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else if phase.error != nil {
                        EmptyView()
                    } else {
                        DS.Color.Fill.default.aspectRatio(16 / 10, contentMode: .fit)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .accessibilityLabel(alt ?? caption ?? "Image")
                if let caption {
                    Text(caption)
                        .font(.system(size: ReaderType.captionSize * fontScale))
                        .foregroundStyle(DS.Color.Text.tertiary)
                }
            }
        case let .code(code):
            ScrollView(.horizontal) {
                Text(code)
                    .font(.system(size: ReaderType.codeSize * fontScale, design: .monospaced))
                    .foregroundStyle(DS.Color.Text.primary)
                    .padding(Spacing.md)
            }
            .background(DS.Color.Fill.default, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
            .contextMenu {
                Button("Copy", systemImage: "doc.on.doc") { UIPasteboardShim.copy(code) }
            }
        case let .list(ordered, items):
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                        Text(ordered ? "\(index + 1)." : "•")
                            .font(ReaderType.font(size: ReaderType.bodySize * fontScale, face: face))
                            .foregroundStyle(DS.Color.Text.tertiary)
                            .frame(minWidth: Spacing.lg, alignment: .trailing)
                        Text(item.attributed)
                            .font(ReaderType.font(size: ReaderType.bodySize * fontScale, face: face))
                            .foregroundStyle(DS.Color.Text.primary)
                    }
                }
            }
        case .rule:
            Divider().padding(.vertical, Spacing.sm)
        }
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case ...1: ReaderType.h1Size
        case 2: ReaderType.h2Size
        default: ReaderType.h3Size
        }
    }
}

/// The one place the pasteboard is touched. Kept behind a tiny shim so the reader stays pure SwiftUI.
enum UIPasteboardShim {
    @MainActor
    static func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
}

struct TypographySheet: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Picker("Typeface", selection: $settings.readerFace) {
                    ForEach(ReaderFace.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Theme", selection: $settings.readerTheme) {
                    ForEach(ReaderTheme.allCases) { Text($0.title).tag($0) }
                }
                HStack {
                    Image(systemName: "textformat.size.smaller")
                    Slider(value: $settings.readerFontScale, in: 0.8...1.6, step: 0.05)
                    Image(systemName: "textformat.size.larger")
                }
                Text("Sample: A thousand tons of volcanic rock replace concrete and steel in Petra Heights.")
                    .font(ReaderType.font(size: ReaderType.bodySize * settings.readerFontScale, face: settings.readerFace))
            }
            .navigationTitle("Typography")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
