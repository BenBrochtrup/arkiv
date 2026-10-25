import ImageIO
import UIKit
import Vision

struct VisionTextRecognizer: ImageTextRecognizing, Sendable {
    func recognizeText(in image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRRecognitionError.unsupportedImage
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await Task.detached(priority: .userInitiated) {
            let result = try Self.recognizeText(in: cgImage, orientation: orientation)
            try Task.checkCancellation()
            return result
        }.value
    }

    private static func recognizeText(
        in image: CGImage,
        orientation: CGImagePropertyOrientation
    ) throws -> OCRResult {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(
            cgImage: image,
            orientation: orientation,
            options: [:]
        )

        do {
            try handler.perform([request])
        } catch {
            throw OCRRecognitionError.processingFailed
        }

        let blocks = (request.results ?? [])
            .compactMap(Self.makeTextBlock)
            .sorted { first, second in
                if abs(first.boundingBox.minY - second.boundingBox.minY) > 0.02 {
                    return first.boundingBox.minY > second.boundingBox.minY
                }

                return first.boundingBox.minX < second.boundingBox.minX
            }

        return OCRResult(
            fullText: blocks.map(\.text).joined(separator: "\n"),
            blocks: blocks
        )
    }

    private static func makeTextBlock(
        from observation: VNRecognizedTextObservation
    ) -> OCRTextBlock? {
        guard let candidate = observation.topCandidates(1).first else {
            return nil
        }

        return OCRTextBlock(
            id: UUID(),
            text: candidate.string,
            confidence: candidate.confidence,
            boundingBox: observation.boundingBox
        )
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}
