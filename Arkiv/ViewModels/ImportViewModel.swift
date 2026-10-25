import Observation
import UIKit

@MainActor
@Observable
final class ImportViewModel {
    var selectedImage: UIImage?
    var isLoadingImage = false
    var importError: String?
    var ocrState: OCRState = .idle

    private let textRecognizer: any ImageTextRecognizing

    init(textRecognizer: any ImageTextRecognizing) {
        self.textRecognizer = textRecognizer
    }

    func loadImage(from data: Data?) async {
        isLoadingImage = true
        importError = nil
        ocrState = .idle
        defer { isLoadingImage = false }

        do {
            guard let data else {
                throw ImageImportError.invalidData
            }

            guard let image = UIImage(data: data) else {
                throw ImageImportError.invalidData
            }

            selectedImage = image
            ocrState = .recognizing

            do {
                let result = try await textRecognizer.recognizeText(in: image)
                ocrState = result.blocks.isEmpty ? .noText : .completed(result)
            } catch is CancellationError {
                return
            } catch {
                ocrState = .failed(error.localizedDescription)
            }
        } catch is CancellationError {
            return
        } catch {
            importError = error.localizedDescription
        }
    }
}

enum OCRState {
    case idle
    case recognizing
    case noText
    case completed(OCRResult)
    case failed(String)
}

private enum ImageImportError: LocalizedError {
    case invalidData

    var errorDescription: String? {
        "Arkiv could not load that image. Please try another screenshot."
    }
}
