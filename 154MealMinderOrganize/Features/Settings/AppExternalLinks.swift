import Foundation

/// Central URLs for Settings (privacy, terms, etc.). Replace host paths when your live pages exist.
enum AppExternalLink {
    case privacyPolicy
    case termsOfUse

    /// Absolute URL strings for Safari / `UIApplication.shared.open`.
    private var rawValue: String {
        switch self {
        case .privacyPolicy:
            return "https://mealminder154organize.site/privacy/139"
        case .termsOfUse:
            return "https://mealminder154organize.site/terms/139"
        }
    }

    var url: URL? {
        URL(string: rawValue)
    }
}
