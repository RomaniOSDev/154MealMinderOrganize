import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private var markdownText: AttributedString {
        if let attributed = try? AttributedString(
            markdown: BundledLegalContent.privacyMarkdown,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        ) {
            return attributed
        }
        return AttributedString(BundledLegalContent.privacyMarkdown)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(markdownText)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color.appPrimary)
        .toolbarBackground(Color.appSurface.opacity(0.92), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    AppHaptics.lightTap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.appAccent, Color.appSurface)
                        .font(.system(size: 26, weight: .bold))
                        .accessibilityLabel("Close")
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .screenBackground()
        .preferredColorScheme(.dark)
    }
}
