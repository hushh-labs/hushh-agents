import SwiftUI

// MARK: - Hushh Typography

/// Headings → Playfair Display (serif)
/// Body / UI → Manrope (sans-serif)
///
/// Usage:
///   .font(.hushhHeading(.title))
///   .font(.hushhBody(.body))

extension Font {

    // ── Playfair Display (Headings) ──────────────────────────

    /// Playfair Display heading mapped to a SwiftUI TextStyle size.
    static func hushhHeading(_ style: HushhTextStyle) -> Font {
        switch style {
        case .largeTitle:
            return .custom("PlayfairDisplay-Bold", size: 34, relativeTo: .largeTitle)
        case .title:
            return .custom("PlayfairDisplay-Bold", size: 28, relativeTo: .title)
        case .title2:
            return .custom("PlayfairDisplay-Bold", size: 22, relativeTo: .title2)
        case .title3:
            return .custom("PlayfairDisplay-SemiBold", size: 20, relativeTo: .title3)
        case .headline:
            return .custom("PlayfairDisplay-SemiBold", size: 17, relativeTo: .headline)
        default:
            return .custom("PlayfairDisplay-Regular", size: 17, relativeTo: .body)
        }
    }

    // ── Manrope (Body / UI) ─────────────────────────────────

    /// Manrope body text mapped to a SwiftUI TextStyle size.
    static func hushhBody(_ style: HushhTextStyle, weight: Font.Weight? = nil) -> Font {
        let fontName: String
        switch weight {
        case .bold:
            fontName = "Manrope-Bold"
        case .semibold:
            fontName = "Manrope-SemiBold"
        case .medium:
            fontName = "Manrope-Medium"
        default:
            fontName = style.defaultManropeName
        }

        return .custom(fontName, size: style.defaultSize, relativeTo: style.textStyle)
    }
}

// MARK: - Hushh Text Style

enum HushhTextStyle {
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
    case caption2

    var defaultSize: CGFloat {
        switch self {
        case .largeTitle:  return 34
        case .title:       return 28
        case .title2:      return 22
        case .title3:      return 20
        case .headline:    return 17
        case .body:        return 17
        case .callout:     return 16
        case .subheadline: return 15
        case .footnote:    return 13
        case .caption:     return 12
        case .caption2:    return 11
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .largeTitle:  return .largeTitle
        case .title:       return .title
        case .title2:      return .title2
        case .title3:      return .title3
        case .headline:    return .headline
        case .body:        return .body
        case .callout:     return .callout
        case .subheadline: return .subheadline
        case .footnote:    return .footnote
        case .caption:     return .caption
        case .caption2:    return .caption2
        }
    }

    /// Default Manrope weight for a given style.
    var defaultManropeName: String {
        switch self {
        case .headline:
            return "Manrope-SemiBold"
        case .body, .callout, .subheadline:
            return "Manrope-Regular"
        case .footnote, .caption, .caption2:
            return "Manrope-Medium"
        default:
            return "Manrope-Bold"
        }
    }
}
