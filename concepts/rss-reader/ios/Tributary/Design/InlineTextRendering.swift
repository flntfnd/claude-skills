import SwiftUI
import TributaryCore

/// Maps the core's inline runs onto AttributedString presentation intents, which `Text`
/// renders natively: bold, italic, code, and tappable links.
extension InlineText {
    var attributed: AttributedString {
        var result = AttributedString()
        for run in runs {
            var piece = AttributedString(run.text)
            var intent: InlinePresentationIntent = []
            if run.isBold { intent.insert(.stronglyEmphasized) }
            if run.isItalic { intent.insert(.emphasized) }
            if run.isCode { intent.insert(.code) }
            if !intent.isEmpty { piece.inlinePresentationIntent = intent }
            if let link = run.link {
                piece.link = link
                piece.foregroundColor = DS.Color.Text.link
            }
            result.append(piece)
        }
        return result
    }
}
