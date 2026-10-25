import CoreGraphics
import Foundation

struct OCRTextBlock: Identifiable, Sendable {
    let id: UUID
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

struct OCRResult: Sendable {
    let fullText: String
    let blocks: [OCRTextBlock]
}

enum OCRRecognitionError: LocalizedError, Sendable {
    case unsupportedImage
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedImage:
            "Arkiv could not prepare this image for text recognition."
        case .processingFailed:
            "Arkiv could not recognize text in this image. Please try another screenshot."
        }
    }
}
