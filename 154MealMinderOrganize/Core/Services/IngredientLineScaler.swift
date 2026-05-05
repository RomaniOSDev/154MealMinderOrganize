import Foundation

enum IngredientLineScaler {
    static func scaledLine(_ line: String, factor: Double) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, factor != 1, factor > 0 else { return line }

        if let rewritten = rewriteLeadingRationalQuantity(in: trimmed, factor: factor) {
            return rewritten
        }

        if let rewritten = rewriteLeadingDecimalQuantity(in: trimmed, factor: factor) {
            return rewritten
        }

        return trimmed + String(format: " (× %.2g servings scale)", factor)
    }

    /// Handles leading integers and simple fractions like "1/2", "2 1/3".
    private static func rewriteLeadingRationalQuantity(in text: String, factor: Double) -> String? {
        let trimmed = text
        guard let regex = try? NSRegularExpression(
            pattern: #"^(?<num>\d+)/(?<den>\d+)(?<rest>.*)$"#,
            options: []
        ),
              let regex2 = try? NSRegularExpression(
                  pattern: #"^(?<whole>\d+)\s+(?<num>\d+)/(?<den>\d+)(?<rest>.*)$"#,
                  options: []
              ) else {
            return nil
        }

        let ns = trimmed as NSString
        let range = NSRange(location: 0, length: ns.length)

        if let m = regex2.firstMatch(in: trimmed, range: range),
           let wRange = Range(m.range(withName: "whole"), in: trimmed),
           let numRange = Range(m.range(withName: "num"), in: trimmed),
           let denRange = Range(m.range(withName: "den"), in: trimmed),
           let restRange = Range(m.range(withName: "rest"), in: trimmed) {
            let whole = Double(trimmed[wRange]) ?? 0
            let numerator = Double(trimmed[numRange]) ?? 0
            let denominator = Double(trimmed[denRange]) ?? 1
            let qty = whole + numerator / max(1, denominator)
            let scaled = qty * factor
            return formatQuantity(scaled) + String(trimmed[restRange])
        }

        if let m = regex.firstMatch(in: trimmed, range: range),
           let numRange = Range(m.range(withName: "num"), in: trimmed),
           let denRange = Range(m.range(withName: "den"), in: trimmed),
           let restRange = Range(m.range(withName: "rest"), in: trimmed) {
            let numerator = Double(trimmed[numRange]) ?? 0
            let denominator = Double(trimmed[denRange]) ?? 1
            let qty = numerator / max(1, denominator)
            let scaled = qty * factor
            return formatQuantity(scaled) + String(trimmed[restRange])
        }

        return nil
    }

    private static func rewriteLeadingDecimalQuantity(in text: String, factor: Double) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: #"^(?<qty>\d+(?:\.\d+)?)\s+(?<rest>.+)$"#,
            options: []
        ) else { return nil }

        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              let qRange = Range(match.range(withName: "qty"), in: text),
              let restRange = Range(match.range(withName: "rest"), in: text),
              let rawQty = Double(text[qRange]) else {
            return nil
        }

        let scaled = rawQty * factor
        return formatQuantity(scaled) + " " + String(text[restRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func formatQuantity(_ value: Double) -> String {
        let roundedTo3 = round(value * 1000) / 1000
        if abs(roundedTo3 - roundedTo3.rounded()) < 0.001 {
            return String(Int(roundedTo3.rounded()))
        }
        return String(format: "%.2g", roundedTo3)
    }
}
