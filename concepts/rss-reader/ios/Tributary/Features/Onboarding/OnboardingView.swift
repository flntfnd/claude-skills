import AuthenticationServices
import SwiftData
import SwiftUI

/// The first screen. One question, switchable later, nothing lost either way.
struct OnboardingView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @State private var choice: StorageMode = .device
    @State private var showAccount = false
    @State private var seedStarterFeeds = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.base) {
                    Text("TRIBUTARY")
                        .font(.footnote.weight(.semibold))
                        .tracking(0.8)
                        .foregroundStyle(DS.Color.Text.link)
                    Text("Where should Tributary keep your feeds?")
                        .font(.title.bold())
                        .foregroundStyle(DS.Color.Text.primary)
                    Text("Pick the way that fits you. You can switch later and everything moves with you.")
                        .font(.body)
                        .foregroundStyle(DS.Color.Text.secondary)

                    ModeCard(
                        systemImage: "iphone",
                        title: "On this device",
                        body: "No account. Feeds are fetched and stored here, synced between your Apple devices through iCloud. Free, no limits.",
                        isSelected: choice == .device
                    ) { choice = .device }

                    ModeCard(
                        systemImage: "globe",
                        title: "Tributary account",
                        body: "Sign in with Google or Apple. Feeds are fetched by the service and synced everywhere, including the web. Adds newsletters, generated feeds, and other reader apps.",
                        isSelected: choice == .account
                    ) { choice = .account }

                    Toggle("Start with a few good feeds", isOn: $seedStarterFeeds)
                        .font(.subheadline)
                        .tint(DS.Color.Interactive.primary)
                        .padding(.top, Spacing.sm)

                    Text("Either way, everything you save can be exported as OPML, JSON Feed, and Markdown at any time.")
                        .font(.footnote)
                        .foregroundStyle(DS.Color.Text.tertiary)
                }
                .padding(.horizontal, Spacing.base)
                .padding(.top, Spacing.xxl)
                .padding(.bottom, Spacing.section * 2)
            }
            .background(DS.Color.Background.primary)
            .safeAreaInset(edge: .bottom) {
                Button(action: continueTapped) {
                    Text("Continue")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .padding(.horizontal, Spacing.base)
                .padding(.bottom, Spacing.sm)
            }
            .navigationDestination(isPresented: $showAccount) {
                AccountSignInView(useDeviceInstead: {
                    showAccount = false
                    choice = .device
                    continueTapped()
                })
            }
        }
    }

    private func continueTapped() {
        switch choice {
        case .device:
            settings.storageMode = .device
            if seedStarterFeeds { StarterLibrary.seed(in: context) }
        case .account:
            showAccount = true
        }
    }
}

private struct ModeCard: View {
    var systemImage: String
    var title: String
    var description: String
    var isSelected: Bool
    var action: () -> Void

    init(systemImage: String, title: String, body: String, isSelected: Bool, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.title = title
        self.description = body
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundStyle(isSelected ? DS.Color.Interactive.primary : DS.Color.Text.secondary)
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(DS.Color.Text.primary)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? DS.Color.Interactive.primary : DS.Color.Border.strong)
                }
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.Text.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.Background.secondary, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                    .strokeBorder(isSelected ? DS.Color.Interactive.primary : DS.Color.Border.default, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(Motion.interactive, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Account mode needs the service, which does not exist yet (CONCEPT.md phase 0). The screen
/// is real so the flow can be reviewed; the buttons say so instead of pretending.
struct AccountSignInView: View {
    var useDeviceInstead: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.base) {
                Image(systemName: "globe")
                    .font(.system(size: 40))
                    .foregroundStyle(DS.Color.Interactive.primary)
                Text("Tributary account")
                    .font(.title.bold())
                    .foregroundStyle(DS.Color.Text.primary)
                Text("One account, every device, including the web. Feeds are fetched once by the service and synced to you. No passwords.")
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.secondary)

                SignInWithAppleButton(.signIn) { _ in } onCompletion: { _ in }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(Capsule())
                    .disabled(true)
                    .opacity(0.5)

                Button {} label: {
                    Label("Sign in with Google", systemImage: "g.circle")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .disabled(true)

                Button {} label: {
                    Label("Continue with a passkey", systemImage: "person.badge.key")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .disabled(true)

                Text("Account mode arrives with the service. Until then, this device keeps everything, and switching later moves it all across.")
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.tertiary)

                Button("Use on this device instead", action: useDeviceInstead)
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.base)
            }
            .padding(.horizontal, Spacing.base)
            .padding(.top, Spacing.xl)
        }
        .background(DS.Color.Background.primary)
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum StarterLibrary {
    @MainActor
    static func seed(in context: ModelContext) {
        var folders: [String: Folder] = [:]
        for (index, entry) in FeedSubscriber.starterFeeds.enumerated() {
            let feed = Feed(url: entry.url, title: entry.title)
            feed.lane = entry.lane
            feed.sortOrder = index
            if let folder = folders[entry.folder] {
                feed.folder = folder
            } else {
                let folder = Folder(name: entry.folder, sortOrder: folders.count)
                context.insert(folder)
                folders[entry.folder] = folder
                feed.folder = folder
            }
            context.insert(feed)
        }
        try? context.save()
    }
}
