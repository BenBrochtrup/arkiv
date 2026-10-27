import Foundation

enum CandidateEvidence: String, Equatable, Sendable {
    case explicitLabels = "Title and author labels"
    case byRelationship = "Title by author"
    case separatorRelationship = "Title and author separator"
    case adjacentLines = "Adjacent title and author lines"
    case standaloneLine = "Standalone list line"
    case manual = "User added"
}

struct BookCandidate: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var author: String?
    let sourceText: String
    let extractionConfidence: Double
    let evidence: CandidateEvidence
}
