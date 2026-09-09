import SwiftData
import SwiftUI
import TributaryCore

struct UnreadDot: View {
    var body: some View {
        Circle()
            .fill(DS.Color.Status.unread)
            .frame(width: Size.unreadDot, height: Size.unreadDot)
            .accessibilityLabel("Unread")
    }
}

/// Site favicon with a letter fallback, matching the Favicon component in Figma.
struct FaviconView: View {
    var feed: Feed?
    var size: CGFloat = Size.favicon

    private var letter: String {
        String((feed?.displayTitle ?? "•").trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.xs, style: .continuous)
                .fill(DS.Color.Fill.default)
            if let url = feed?.iconURL.flatMap(URL.init(string:)) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        fallback
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Radius.xs, style: .continuous))
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var fallback: some View {
        Text(letter)
            .font(.system(size: size * 0.55, weight: .semibold, design: .rounded))
            .foregroundStyle(DS.Color.Text.secondary)
    }
}

struct SourcesChip: View {
    var count: Int

    var body: some View {
        Label("\(count) sources", systemImage: "square.stack.3d.up")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(DS.Color.Text.link)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(DS.Color.Interactive.primarySubtle, in: Capsule())
    }
}

struct LaneHeader: View {
    var title: String
    var count: Int?

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(DS.Color.Text.secondary)
            Spacer()
            if let count, count > 0 {
                Text("\(count)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DS.Color.Text.tertiary)
            }
        }
        .padding(.top, Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}

enum CardSize { case large, standard }

/// The Today and Timeline card. Large is the Priority lane treatment: image, bigger title,
/// summary. Standard is title and source. Read items drop to secondary text.
struct ArticleCard: View {
    let item: Item
    var size: CardSize = .standard
    var clusterCount: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if size == .large, let cover = item.cover {
                AsyncImage(url: cover) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        DS.Color.Fill.default
                    }
                }
                .frame(height: Size.heroImageHeight)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .accessibilityHidden(true)
            }
            HStack(spacing: Spacing.sm) {
                FaviconView(feed: item.feed, size: Size.faviconSmall)
                Text(item.sourceTitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DS.Color.Text.secondary)
                    .lineLimit(1)
                Text(item.sortDate, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.tertiary)
                Spacer(minLength: 0)
                if !item.isRead { UnreadDot() }
            }
            Text(item.title)
                .font(size == .large ? .title3.weight(.semibold) : .headline)
                .foregroundStyle(item.isRead ? DS.Color.Text.secondary : DS.Color.Text.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            if size == .large, !item.contentText.isEmpty {
                Text(item.contentText)
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.Text.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: Spacing.sm) {
                Text("\(item.readingMinutes) min read")
                    .font(.caption)
                    .foregroundStyle(DS.Color.Text.tertiary)
                if item.isSaved {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(DS.Color.Status.saved)
                        .accessibilityLabel("Saved")
                }
                Spacer(minLength: 0)
                if let clusterCount, clusterCount > 1 { SourcesChip(count: clusterCount) }
            }
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
        .background(DS.Color.Background.secondary, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

/// The Ambient lane, collapsed to one row. Never notifies. Tap to expand into the Timeline.
struct AmbientRow: View {
    var count: Int
    var feeds: [String]

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "tray")
                .foregroundStyle(DS.Color.Text.secondary)
            Text("\(count) new from \(ListFormatter.localizedString(byJoining: feeds))")
                .font(.subheadline)
                .foregroundStyle(DS.Color.Text.secondary)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DS.Color.Text.tertiary)
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
        .background(DS.Color.Fill.secondary, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

/// One a day at most, says why it is here, dismiss silences it for ninety days.
struct ResurfaceCard: View {
    let item: Item
    var reason: String
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "bookmark")
                    .font(.caption)
                    .foregroundStyle(DS.Color.Text.link)
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(DS.Color.Text.link)
                    .lineLimit(1)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.Color.Text.tertiary)
                        .frame(width: Spacing.xl, height: Spacing.xl)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss for ninety days")
            }
            Text(item.title)
                .font(.headline)
                .foregroundStyle(DS.Color.Text.primary)
                .lineLimit(2)
            Text("\(item.sourceTitle) · \(item.readingMinutes) min")
                .font(.footnote)
                .foregroundStyle(DS.Color.Text.tertiary)
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
        .background(DS.Color.Background.secondary, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(DS.Color.Interactive.primarySubtle))
    }
}

struct SkeletonRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            bar(width: 120)
            bar(width: 300)
            bar(width: 240)
            bar(width: 80)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
        .background(DS.Color.Background.secondary, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
    }

    private func bar(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Radius.xs, style: .continuous)
            .fill(DS.Color.Fill.default)
            .frame(width: width, height: 12)
    }
}

struct ErrorBanner: View {
    var title: String
    var message: String
    var retry: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(DS.Color.Status.error)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(DS.Color.Text.primary)
                Text(message).font(.footnote).foregroundStyle(DS.Color.Text.secondary)
            }
            Spacer()
            Button("Retry", action: retry)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.md)
        .background(DS.Color.Fill.default, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}

/// A round Liquid Glass button for the reader's floating chrome.
struct GlassIconButton: View {
    var systemImage: String
    var label: String
    var isActive = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .symbolVariant(isActive ? .fill : .none)
                .foregroundStyle(isActive ? DS.Color.Interactive.primary : DS.Color.Text.primary)
                .frame(width: Size.touchTarget, height: Size.touchTarget)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }
}

extension View {
    /// The card and row background used on every grouped surface.
    func groupedSurface() -> some View {
        background(DS.Color.Background.secondary, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}
