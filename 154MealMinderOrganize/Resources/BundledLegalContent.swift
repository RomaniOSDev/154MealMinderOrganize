import Foundation

enum BundledLegalContent {
    static var privacyMarkdown: String {
        guard let url = Bundle.main.url(forResource: "privacy_policy", withExtension: "md"),
              let text = try? String(contentsOf: url)
        else {
            return "## Privacy Policy\nBundled markdown file missing.\nVisit support if this persists."
        }
        return text
    }
}
