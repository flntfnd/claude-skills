import AVFoundation
import Foundation
import FoundationModels
import Observation

/// On-device summaries through Apple's Foundation Models framework. Off by default, never
/// ranks or hides anything, every output is a card the user asked for. Nothing leaves the device.
actor Summarizer {
    static let shared = Summarizer()

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    static var unavailableReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case let .unavailable(reason):
            switch reason {
            case .deviceNotEligible: return "This device can’t run the on-device model."
            case .appleIntelligenceNotEnabled: return "Turn on Apple Intelligence in Settings to summarize on device."
            case .modelNotReady: return "The on-device model is still downloading."
            @unknown default: return "The on-device model isn’t available right now."
            }
        @unknown default:
            return "The on-device model isn’t available right now."
        }
    }

    func summarize(title: String, text: String) async throws -> String {
        let session = LanguageModelSession(instructions: """
        You summarize articles for a reader who has not read them yet. Write three plain sentences \
        in the article's own terms. No opinions, no bullet points, no preamble. Do not invent facts \
        that are not in the text.
        """)
        let clipped = String(text.prefix(6000))
        let response = try await session.respond(to: "Title: \(title)\n\nArticle:\n\(clipped)")
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Reads an article aloud with the system speech engine, paragraph by paragraph, so the
/// reader can highlight the paragraph being spoken and update the read position as it goes.
@MainActor
@Observable
final class SpeechReader: NSObject {
    private(set) var isSpeaking = false
    private(set) var isPaused = false
    private(set) var currentIndex: Int?
    private var paragraphs: [String] = []
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ paragraphs: [String], from index: Int = 0) {
        stop()
        self.paragraphs = paragraphs.filter { !$0.isEmpty }
        guard !self.paragraphs.isEmpty else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        isSpeaking = true
        isPaused = false
        speakParagraph(at: min(index, self.paragraphs.count - 1))
    }

    func togglePause() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
        } else if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            isPaused = true
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        currentIndex = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func speakParagraph(at index: Int) {
        guard index < paragraphs.count else {
            stop()
            return
        }
        currentIndex = index
        let utterance = AVSpeechUtterance(string: paragraphs[index])
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.postUtteranceDelay = 0.35
        synthesizer.speak(utterance)
    }

    fileprivate func advance() {
        guard isSpeaking, let index = currentIndex else { return }
        speakParagraph(at: index + 1)
    }
}

extension SpeechReader: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.advance() }
    }
}
