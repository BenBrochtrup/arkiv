import UIKit

protocol ImageTextRecognizing: Sendable {
    func recognizeText(in image: UIImage) async throws -> OCRResult
}
