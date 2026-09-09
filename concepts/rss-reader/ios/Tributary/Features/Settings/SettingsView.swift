import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var exportDocument: ArchiveDocument?
    @State private var exportError: String?
    @State private var showExport = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section {
                    LabeledContent("On this device", value: settings.iCloudSyncEnabled ? "iCloud on" : "iCloud off")
                    Toggle("Sync with iCloud", isOn: $settings.iCloudSyncEnabled)
                    Toggle("Archive in iCloud Drive", isOn: $settings.archiveMirrorEnabled)
                    if let last = settings.lastArchiveMirrorAt {
                        Text("Tributary folder updated \(last.formatted(.relative(presentation: .named)))")
                            .font(.footnote).foregroundStyle(DS.Color.Text.tertiary)
                    }
                    NavigationLink("Switch to a Tributary account") { AccountSignInView(useDeviceInstead: { dismiss() }) }
                    if let failure = settings.storeFailureMessage {
                        Text(failure).font(.footnote).foregroundStyle(DS.Color.Status.error)
                    }
                } header: {
                    Text("Where your data lives")
                } footer: {
                    Text("iCloud sync changes take effect the next time the app launches. The iCloud Drive archive is your data in open formats: OPML, JSON Feed, Markdown, JSON. Readable without the app.")
                }

                Section("Reading") {
                    Picker("Typeface", selection: $settings.readerFace) {
                        ForEach(ReaderFace.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Theme", selection: $settings.readerTheme) {
                        ForEach(ReaderTheme.allCases) { Text($0.title).tag($0) }
                    }
                    HStack {
                        Text("Text size")
                        Slider(value: $settings.readerFontScale, in: 0.8...1.6, step: 0.05)
                        Text("\(Int(settings.readerFontScale * 100))%").monospacedDigit().foregroundStyle(DS.Color.Text.tertiary)
                    }
                    Toggle("Reader view by default", isOn: $settings.readerViewByDefault)
                    Toggle("Open links in Safari", isOn: $settings.openLinksInSafari)
                }

                Section {
                    LabeledContent("Background refresh", value: "When iOS allows")
                    Picker("Notifications", selection: $settings.notifications) {
                        ForEach(NotificationMode.allCases) { Text($0.title).tag($0) }
                    }
                    if let last = settings.lastRefreshAt {
                        LabeledContent("Last refresh", value: last.formatted(.relative(presentation: .named)))
                    }
                } header: {
                    Text("Refresh and notifications")
                } footer: {
                    Text("Only Priority-lane feeds can notify without a rule. There is no unread-count nudge.")
                }

                Section {
                    Button("Export everything…", systemImage: "square.and.arrow.up") { export() }
                    if let error = exportError { Text(error).font(.footnote).foregroundStyle(DS.Color.Status.error) }
                    Text("Import from another reader lives in the Feeds tab: OPML from any reader.")
                        .font(.footnote).foregroundStyle(DS.Color.Text.tertiary)
                } header: {
                    Text("Your data")
                } footer: {
                    Text("A full archive: subscriptions.opml, per-item state, every saved article as Markdown and HTML, highlights. The same file that moves you between modes.")
                }

                Section {
                    Toggle("Summaries on device", isOn: $settings.summariesEnabled)
                        .disabled(!Summarizer.isAvailable)
                    if let reason = Summarizer.unavailableReason {
                        Text(reason).font(.footnote).foregroundStyle(DS.Color.Text.tertiary)
                    }
                    Toggle("Resurface saved articles", isOn: $settings.resurfacingEnabled)
                } header: {
                    Text("Intelligence")
                } footer: {
                    Text("Summaries run on the device with Apple’s on-device model. Nothing leaves the phone, nothing is ranked or hidden. Every summary is a card you asked for.")
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                    Link("Concept and source", destination: URL(string: "https://github.com/flntfnd/claude-skills")!)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .fileExporter(isPresented: $showExport, document: exportDocument, contentType: .folder, defaultFilename: exportDocument?.wrapper.preferredFilename) { result in
                if case let .failure(error) = result { exportError = error.localizedDescription }
                exportDocument = nil
            }
        }
    }

    private func export() {
        do {
            exportDocument = ArchiveDocument(wrapper: try ArchiveBuilder.build(context: context, settings: settings))
            showExport = true
        } catch {
            exportError = error.localizedDescription
        }
    }
}
