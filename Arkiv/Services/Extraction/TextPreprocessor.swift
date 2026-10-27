import Foundation

struct NormalizedOCRLine: Sendable {
    let original: String
    let normalized: String
}

struct TextPreprocessor: Sendable {
    func lines(from text: String) -> [NormalizedOCRLine] {
        text.components(separatedBy: .newlines).compactMap { line in
            let normalized = normalize(line)
            guard !normalized.isEmpty else {
                return nil
            }

            return NormalizedOCRLine(original: line.trimmingCharacters(in: .whitespacesAndNewlines), normalized: normalized)
        }
    }

    func normalize(_ text: String) -> String {
        var value = text.precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "’", with: "'")

        value = value.replacingOccurrences(of: #"^\s*(?:[•●▪◦]|\d+[.)])\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
