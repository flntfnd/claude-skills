import SwiftUI

/// The token layer. Names match the Figma variables one for one
/// (color/semantic/background/primary -> DS.Color.Background.primary) so handoff needs no
/// translation table. Colors resolve through the asset catalog so light and dark are one
/// definition each.
enum DS {
    enum Color {
        enum Background {
            static let primary = SwiftUI.Color("BackgroundPrimary")
            static let secondary = SwiftUI.Color("BackgroundSecondary")
            static let elevated = SwiftUI.Color("BackgroundElevated")
            static let grouped = SwiftUI.Color("BackgroundGrouped")
            static let reader = SwiftUI.Color("BackgroundReader")
            static let sepia = SwiftUI.Color("BackgroundSepia")
        }

        enum Text {
            static let primary = SwiftUI.Color("TextPrimary")
            static let secondary = SwiftUI.Color("TextSecondary")
            static let tertiary = SwiftUI.Color("TextTertiary")
            static let onAccent = SwiftUI.Color("TextOnAccent")
            static let link = SwiftUI.Color("TextLink")
        }

        enum Border {
            static let `default` = SwiftUI.Color("BorderDefault")
            static let strong = SwiftUI.Color("BorderStrong")
        }

        enum Fill {
            static let `default` = SwiftUI.Color("FillDefault")
            static let secondary = SwiftUI.Color("FillSecondary")
            static let selected = SwiftUI.Color("FillSelected")
        }

        enum Interactive {
            static let primary = SwiftUI.Color("InteractivePrimary")
            static let primaryPressed = SwiftUI.Color("InteractivePrimaryPressed")
            static let primarySubtle = SwiftUI.Color("InteractivePrimarySubtle")
        }

        enum Status {
            static let unread = SwiftUI.Color("StatusUnread")
            static let saved = SwiftUI.Color("StatusSaved")
            static let error = SwiftUI.Color("StatusError")
            static let success = SwiftUI.Color("StatusSuccess")
            static let info = SwiftUI.Color("StatusInfo")
        }
    }
}

/// Matches `spacing/*` in Figma. Nothing outside this scale.
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
    static let section: CGFloat = 64
}

/// Matches `radius/*` in Figma.
enum Radius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let thumbnail: CGFloat = 8
    static let control: CGFloat = 10
}

enum GlassTokens {
    enum Radius {
        static let card: CGFloat = 28
        static let pill: CGFloat = 999
        static let sheet: CGFloat = 34
    }

    enum Padding {
        static let pill = EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        static let iconButton: CGFloat = 12
    }
}

enum Size {
    static let touchTarget: CGFloat = 44
    static let favicon: CGFloat = 20
    static let faviconSmall: CGFloat = 16
    static let unreadDot: CGFloat = 8
    static let thumbnail: CGFloat = 64
    static let readerMeasure: CGFloat = 640
    static let heroImageHeight: CGFloat = 185
}

/// Motion tokens. The concept leaves motion parameters as a design decision (section 11,
/// decision 5). These are the system springs Apple recommends for each purpose and are the
/// placeholders to replace once motion is specified. Interactive = user-triggered (spring),
/// automated = system-triggered (ease).
enum Motion {
    static let interactive: Animation = .snappy
    static let gentle: Animation = .smooth
    static let automated: Animation = .easeInOut(duration: 0.25)
    static let readState: Animation = .easeOut(duration: 0.2)
}

/// Reader typography scale from the Figma Reader/* styles. Sizes scale with the user's
/// preference and with Dynamic Type through `ScaledMetric` in the views that use them.
enum ReaderType {
    static let bodySize: CGFloat = 19
    static let bodyLeading: CGFloat = 30
    static let leadSize: CGFloat = 21
    static let displaySize: CGFloat = 30
    static let h1Size: CGFloat = 26
    static let h2Size: CGFloat = 22
    static let h3Size: CGFloat = 19
    static let captionSize: CGFloat = 14
    static let metaSize: CGFloat = 13
    static let codeSize: CGFloat = 15

    static func design(for face: ReaderFace) -> Font.Design {
        switch face {
        case .system: .default
        case .serif: .serif
        case .rounded: .rounded
        case .mono: .monospaced
        }
    }

    static func font(size: CGFloat, weight: Font.Weight = .regular, face: ReaderFace) -> Font {
        .system(size: size, weight: weight, design: design(for: face))
    }
}
