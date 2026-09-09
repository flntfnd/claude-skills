import Foundation
import Observation

enum StorageMode: String, CaseIterable, Sendable {
    case device
    case account
}

enum ReaderTheme: String, CaseIterable, Sendable, Identifiable {
    case system, light, dark, sepia, black
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        case .sepia: "Sepia"
        case .black: "Black"
        }
    }
}

enum ReaderFace: String, CaseIterable, Sendable, Identifiable {
    case system, serif, rounded, mono
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "System"
        case .serif: "Serif"
        case .rounded: "Rounded"
        case .mono: "Mono"
        }
    }
}

enum NotificationMode: String, CaseIterable, Sendable, Identifiable {
    case off, priority, rules
    var id: String { rawValue }
    var title: String {
        switch self {
        case .off: "Off"
        case .priority: "Priority only"
        case .rules: "Priority and rules"
        }
    }
}

/// Every user preference, backed by UserDefaults and observable from views. Keys are stable
/// because they are exported in the archive's settings.json.
@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    var storageMode: StorageMode? { didSet { defaults.set(storageMode?.rawValue, forKey: Key.storageMode) } }
    var iCloudSyncEnabled: Bool { didSet { defaults.set(iCloudSyncEnabled, forKey: Key.iCloudSync) } }
    var archiveMirrorEnabled: Bool { didSet { defaults.set(archiveMirrorEnabled, forKey: Key.archiveMirror) } }
    var readerFontScale: Double { didSet { defaults.set(readerFontScale, forKey: Key.readerFontScale) } }
    var readerTheme: ReaderTheme { didSet { defaults.set(readerTheme.rawValue, forKey: Key.readerTheme) } }
    var readerFace: ReaderFace { didSet { defaults.set(readerFace.rawValue, forKey: Key.readerFace) } }
    var readerViewByDefault: Bool { didSet { defaults.set(readerViewByDefault, forKey: Key.readerViewByDefault) } }
    var openLinksInSafari: Bool { didSet { defaults.set(openLinksInSafari, forKey: Key.openLinksInSafari) } }
    var notifications: NotificationMode { didSet { defaults.set(notifications.rawValue, forKey: Key.notifications) } }
    var summariesEnabled: Bool { didSet { defaults.set(summariesEnabled, forKey: Key.summaries) } }
    var resurfacingEnabled: Bool { didSet { defaults.set(resurfacingEnabled, forKey: Key.resurfacing) } }
    var lastRefreshAt: Date? { didSet { defaults.set(lastRefreshAt, forKey: Key.lastRefresh) } }
    var resurfaceDismissedUntil: Date? { didSet { defaults.set(resurfaceDismissedUntil, forKey: Key.resurfaceDismissed) } }
    var lastResurfacedItemID: String? { didSet { defaults.set(lastResurfacedItemID, forKey: Key.lastResurfaced) } }
    var lastResurfacedAt: Date? { didSet { defaults.set(lastResurfacedAt, forKey: Key.lastResurfacedAt) } }
    var lastArchiveMirrorAt: Date? { didSet { defaults.set(lastArchiveMirrorAt, forKey: Key.lastMirror) } }

    /// Set at launch when the store could not open with CloudKit. Shown in Settings.
    var storeFailureMessage: String?

    private enum Key {
        static let storageMode = "storage.mode"
        static let iCloudSync = "storage.icloudSync"
        static let archiveMirror = "storage.archiveMirror"
        static let readerFontScale = "reader.fontScale"
        static let readerTheme = "reader.theme"
        static let readerFace = "reader.face"
        static let readerViewByDefault = "reader.readerViewByDefault"
        static let openLinksInSafari = "reader.openLinksInSafari"
        static let notifications = "notifications.mode"
        static let summaries = "intelligence.summaries"
        static let resurfacing = "today.resurfacing"
        static let lastRefresh = "refresh.lastAt"
        static let resurfaceDismissed = "today.resurfaceDismissedUntil"
        static let lastResurfaced = "today.lastResurfacedItemID"
        static let lastResurfacedAt = "today.lastResurfacedAt"
        static let lastMirror = "archive.lastMirrorAt"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        storageMode = defaults.string(forKey: Key.storageMode).flatMap(StorageMode.init(rawValue:))
        iCloudSyncEnabled = defaults.object(forKey: Key.iCloudSync) as? Bool ?? true
        archiveMirrorEnabled = defaults.object(forKey: Key.archiveMirror) as? Bool ?? true
        readerFontScale = defaults.object(forKey: Key.readerFontScale) as? Double ?? 1.0
        readerTheme = defaults.string(forKey: Key.readerTheme).flatMap(ReaderTheme.init(rawValue:)) ?? .system
        readerFace = defaults.string(forKey: Key.readerFace).flatMap(ReaderFace.init(rawValue:)) ?? .system
        readerViewByDefault = defaults.object(forKey: Key.readerViewByDefault) as? Bool ?? true
        openLinksInSafari = defaults.object(forKey: Key.openLinksInSafari) as? Bool ?? false
        notifications = defaults.string(forKey: Key.notifications).flatMap(NotificationMode.init(rawValue:)) ?? .priority
        summariesEnabled = defaults.bool(forKey: Key.summaries)
        resurfacingEnabled = defaults.object(forKey: Key.resurfacing) as? Bool ?? true
        lastRefreshAt = defaults.object(forKey: Key.lastRefresh) as? Date
        resurfaceDismissedUntil = defaults.object(forKey: Key.resurfaceDismissed) as? Date
        lastResurfacedItemID = defaults.string(forKey: Key.lastResurfaced)
        lastResurfacedAt = defaults.object(forKey: Key.lastResurfacedAt) as? Date
        lastArchiveMirrorAt = defaults.object(forKey: Key.lastMirror) as? Date
    }

    /// The exportable subset, written to settings.json in the archive.
    var exportable: [String: String] {
        [
            Key.readerFontScale: String(readerFontScale),
            Key.readerTheme: readerTheme.rawValue,
            Key.readerFace: readerFace.rawValue,
            Key.readerViewByDefault: String(readerViewByDefault),
            Key.openLinksInSafari: String(openLinksInSafari),
            Key.notifications: notifications.rawValue,
            Key.summaries: String(summariesEnabled),
            Key.resurfacing: String(resurfacingEnabled),
        ]
    }
}
