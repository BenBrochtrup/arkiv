import CoreGraphics
import Foundation

enum OCRBlockReviewStatus: String, Sendable {
    case unreviewed
    case confirmed
    case ignored
}

enum OCRBlockRole: String, Sendable {
    case none
    case title
    case author
}

struct EditableOCRBlock: Identifiable, Sendable {
    let id: UUID
    var sourceBlockIDs: [UUID]
    var text: String
    let confidence: Float
    var boundingBox: CGRect
    var status: OCRBlockReviewStatus = .unreviewed
    var role: OCRBlockRole = .none
}
