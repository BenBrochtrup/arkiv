import Foundation

struct BookCandidateExtractor: Sendable {
    private let preprocessor = TextPreprocessor()

    private let boilerplatePhrases = [
        "follow for more",
        "link in bio",
        "like and subscribe",
        "save this post",
        "book recommendations",
        "my favorite books",
        "my favorite reads",
        "books you need to read"
    ]

    func extract(from result: OCRResult) -> [BookCandidate] {
        let lines = preprocessor.lines(from: result.fullText)
        var candidates: [BookCandidate] = []
        var consumedLineIndexes = Set<Int>()

        for index in lines.indices {
            let line = lines[index]
            let lowercased = line.normalized.lowercased()

            if lowercased.hasPrefix("title:") {
                let title = line.normalized.dropFirst("title:".count).trimmingCharacters(in: .whitespaces)
                if !title.isEmpty, index + 1 < lines.count,
                   lines[index + 1].normalized.lowercased().hasPrefix("author:") {
                    let author = lines[index + 1].normalized.dropFirst("author:".count).trimmingCharacters(in: .whitespaces)
                    candidates.append(candidate(
                        title: String(title),
                        author: author.isEmpty ? nil : String(author),
                        sourceText: "\(line.original)\n\(lines[index + 1].original)",
                        confidence: 0.95,
                        evidence: .explicitLabels
                    ))
                    consumedLineIndexes.formUnion([index, index + 1])
                }
            }

            if let relationship = relationship(in: line.normalized) {
                candidates.append(candidate(
                    title: relationship.title,
                    author: relationship.author,
                    sourceText: line.original,
                    confidence: relationship.evidence == .byRelationship ? 0.90 : 0.80,
                    evidence: relationship.evidence
                ))
                consumedLineIndexes.insert(index)
            }
        }

        for index in lines.indices where !consumedLineIndexes.contains(index) {
            guard index + 1 < lines.count,
                  !consumedLineIndexes.contains(index + 1),
                  isLikelyTitle(lines[index].normalized),
                  isLikelyAuthor(lines[index + 1].normalized) else {
                continue
            }

            candidates.append(candidate(
                title: lines[index].normalized,
                author: lines[index + 1].normalized,
                sourceText: "\(lines[index].original)\n\(lines[index + 1].original)",
                confidence: 0.80,
                evidence: .adjacentLines
            ))
            consumedLineIndexes.formUnion([index, index + 1])
        }

        for index in lines.indices where !consumedLineIndexes.contains(index) {
            let line = lines[index]
            guard isLikelyTitle(line.normalized) else {
                continue
            }

            candidates.append(candidate(
                title: line.normalized,
                author: nil,
                sourceText: line.original,
                confidence: 0.65,
                evidence: .standaloneLine
            ))
        }

        return deduplicated(candidates)
    }

    private func relationship(in line: String) -> (title: String, author: String, evidence: CandidateEvidence)? {
        let lowercased = line.lowercased()

        if let range = lowercased.range(of: " by ") {
            let title = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let author = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            guard isLikelyTitle(title), isLikelyAuthor(author) else {
                return nil
            }
            return (title, author, .byRelationship)
        }

        for separator in [" — ", " – ", " - "] {
            guard let range = line.range(of: separator) else {
                continue
            }

            let title = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let author = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            guard isLikelyTitle(title), isLikelyAuthor(author) else {
                continue
            }
            return (title, author, .separatorRelationship)
        }

        return nil
    }

    private func isLikelyTitle(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = normalized.lowercased()
        let words = normalized.split(whereSeparator: { $0 == " " || $0 == "\t" })

        guard !normalized.isEmpty,
              words.count <= 14,
              normalized.count <= 100,
              !boilerplatePhrases.contains(where: { lowercased == $0 || lowercased.contains($0) }),
              !lowercased.hasPrefix("title:"),
              !lowercased.hasPrefix("author:") else {
            return false
        }

        return !normalized.hasSuffix("!") && !normalized.hasSuffix("?")
    }

    private func isLikelyAuthor(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = normalized.split(separator: " ")

        guard !normalized.isEmpty,
              (1...5).contains(words.count),
              normalized != normalized.uppercased(),
              !normalized.contains("!") && !normalized.contains("?") else {
            return false
        }

        return words.allSatisfy { word in
            guard let first = word.first else { return false }
            return first.isUppercase || word.contains(".")
        }
    }

    private func candidate(
        title: String,
        author: String?,
        sourceText: String,
        confidence: Double,
        evidence: CandidateEvidence
    ) -> BookCandidate {
        BookCandidate(
            id: UUID(),
            title: title,
            author: author,
            sourceText: sourceText,
            extractionConfidence: confidence,
            evidence: evidence
        )
    }

    private func deduplicated(_ candidates: [BookCandidate]) -> [BookCandidate] {
        var result: [BookCandidate] = []
        var indexes: [String: Int] = [:]

        for candidate in candidates {
            let key = normalizedKey(title: candidate.title, author: candidate.author)
            if let existingIndex = indexes[key] {
                if candidate.extractionConfidence > result[existingIndex].extractionConfidence {
                    result[existingIndex] = candidate
                }
            } else {
                indexes[key] = result.count
                result.append(candidate)
            }
        }

        return result
    }

    private func normalizedKey(title: String, author: String?) -> String {
        let normalizedTitle = preprocessor.normalize(title).lowercased()
        let normalizedAuthor = preprocessor.normalize(author ?? "").lowercased()
        return "\(normalizedTitle)|\(normalizedAuthor)"
    }
}
