import SwiftUI

// MARK: - Hushh Typography (System SF Fonts — Apple HIG Aligned)

/// All typography uses the system San Francisco font to match
/// Apple's native Settings / Notes app appearance.
///
/// Usage:
///   .font(.hushhHeading(.title))
///   .font(.hushhBody(.body))

extension Font {

    // ── Headings (SF with rounded design for warmth) ────────

    static func hushhHeading(_ style: HushhTextStyle) -> Font {
        switch style {
        case .largeTitle:
            return .system(.largeTitle, design: .default, weight: .bold)
        case .title:
            return .system(.title, design: .default, weight: .bold)
        case .title2:
            return .system(.title2, design: .default, weight: .bold)
        case .title3:
            return .system(.title3, design: .default, weight: .semibold)
        case .headline:
            return .system(.headline, design: .default, weight: .semibold)
        default:
            return .system(.body, design: .default)
        }
    }

    // ── Body / UI (SF system) ───────────────────────────────

    static func hushhBody(_ style: HushhTextStyle, weight: Font.Weight? = nil) -> Font {
        let resolvedWeight = weight ?? style.defaultWeight
        return .system(style.textStyle, design: .default, weight: resolvedWeight)
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

    var defaultWeight: Font.Weight {
        switch self {
        case .headline:
            return .semibold
        case .body, .callout, .subheadline:
            return .regular
        case .footnote, .caption, .caption2:
            return .medium
        default:
            return .bold
        }
    }
}
