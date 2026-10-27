import Observation
import UIKit

@MainActor
@Observable
final class ImportViewModel {
    var selectedImage: UIImage?
    var isLoadingImage = false
    var importError: String?
    var ocrState: OCRState = .idle
    var ocrSelection = OCRSelection()
    var isProcessingRegion = false
    var isShowingFocusedOCR = false
    var candidates: [BookCandidate] = []
    var editableOCRBlocks: [EditableOCRBlock] = []

    private let textRecognizer: any ImageTextRecognizing
    private let candidateExtractor: BookCandidateExtractor
    private var fullImageOCRState: OCRState = .idle
    private var manualCandidates: [BookCandidate] = []

    init(
        textRecognizer: any ImageTextRecognizing,
        candidateExtractor: BookCandidateExtractor = BookCandidateExtractor()
    ) {
        self.textRecognizer = textRecognizer
        self.candidateExtractor = candidateExtractor
    }

    func loadImage(from data: Data?) async {
        isLoadingImage = true
        importError = nil
        ocrState = .idle
        fullImageOCRState = .idle
        isShowingFocusedOCR = false
        candidates = []
        manualCandidates = []
        defer { isLoadingImage = false }

        do {
            guard let data else {
                throw ImageImportError.invalidData
            }

            guard let image = UIImage(data: data) else {
                throw ImageImportError.invalidData
            }

            selectedImage = image
            ocrSelection = OCRSelection()
            editableOCRBlocks = []
            ocrState = .recognizing

            do {
                let result = try await textRecognizer.recognizeText(in: image)
                let state: OCRState = result.blocks.isEmpty ? .noText : .completed(result)
                fullImageOCRState = state
                ocrState = state
                updateCandidates(for: state)
                updateEditableBlocks(for: state)
            } catch is CancellationError {
                return
            } catch {
                let state = OCRState.failed(error.localizedDescription)
                fullImageOCRState = state
                ocrState = state
                updateCandidates(for: state)
                updateEditableBlocks(for: state)
            }
        } catch is CancellationError {
            return
        } catch {
            importError = error.localizedDescription
        }
    }

    func toggleOCRBlock(_ id: UUID) {
        if ocrSelection.blockIDs.contains(id) {
            ocrSelection.blockIDs.remove(id)
        } else {
            ocrSelection.blockIDs.insert(id)
        }
    }

    func updateSelectedRegion(_ region: CGRect?) {
        ocrSelection.region = region
    }

    func recognizeSelectedRegion() async {
        guard let image = selectedImage,
              let region = ocrSelection.region else {
            return
        }

        isProcessingRegion = true
        importError = nil
        defer { isProcessingRegion = false }

        do {
            let croppedImage = try ImageCropper.crop(image, to: region)
            let result = try await textRecognizer.recognizeText(in: croppedImage)
            let mappedResult = ImageCropper.map(result, to: region)

            ocrState = mappedResult.blocks.isEmpty ? .noText : .completed(mappedResult)
            isShowingFocusedOCR = true
            updateCandidates(for: ocrState)
            updateEditableBlocks(for: ocrState)
        } catch is CancellationError {
            return
        } catch {
            ocrState = .failed(error.localizedDescription)
            isShowingFocusedOCR = true
            updateCandidates(for: ocrState)
            updateEditableBlocks(for: ocrState)
        }
    }

    func showFullImageOCR() {
        ocrState = fullImageOCRState
        isShowingFocusedOCR = false
        updateCandidates(for: ocrState)
        updateEditableBlocks(for: ocrState)
    }

    func addManualCandidate(title: String, author: String?) {
        let candidate = BookCandidate(
            id: UUID(),
            title: title,
            author: author,
            sourceText: "Manual entry",
            extractionConfidence: 1.0,
            evidence: .manual
        )
        manualCandidates.append(candidate)
        updateCandidates(for: ocrState)
    }

    private func updateCandidates(for state: OCRState) {
        guard case .completed(let result) = state else {
            candidates = manualCandidates
            return
        }

        candidates = candidateExtractor.extract(from: result) + manualCandidates
    }

    func updateOCRBlockText(_ id: UUID, text: String) {
        guard let index = editableOCRBlocks.firstIndex(where: { $0.id == id }) else {
            return
        }
        editableOCRBlocks[index].text = text
    }

    func updateOCRBlockStatus(_ id: UUID, status: OCRBlockReviewStatus) {
        guard let index = editableOCRBlocks.firstIndex(where: { $0.id == id }) else {
            return
        }
        editableOCRBlocks[index].status = status
    }

    func updateOCRBlockRole(_ id: UUID, role: OCRBlockRole) {
        guard let index = editableOCRBlocks.firstIndex(where: { $0.id == id }) else {
            return
        }
        editableOCRBlocks[index].role = role
    }

    func splitOCRBlock(_ id: UUID) {
        guard let index = editableOCRBlocks.firstIndex(where: { $0.id == id }) else {
            return
        }

        let block = editableOCRBlocks[index]
        let pieces = block.text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard pieces.count > 1 else {
            return
        }

        let replacement = pieces.map { text in
            EditableOCRBlock(
                id: UUID(),
                sourceBlockIDs: block.sourceBlockIDs,
                text: text,
                confidence: block.confidence,
                boundingBox: block.boundingBox,
                status: block.status,
                role: block.role
            )
        }
        editableOCRBlocks.replaceSubrange(index...index, with: replacement)
    }

    func combineOCRBlocks(sourceID: UUID, targetID: UUID) {
        guard sourceID != targetID,
              let sourceIndex = editableOCRBlocks.firstIndex(where: { $0.id == sourceID }),
              let targetIndex = editableOCRBlocks.firstIndex(where: { $0.id == targetID }) else {
            return
        }

        let source = editableOCRBlocks[sourceIndex]
        let target = editableOCRBlocks[targetIndex]
        let merged = EditableOCRBlock(
            id: target.id,
            sourceBlockIDs: target.sourceBlockIDs + source.sourceBlockIDs,
            text: [target.text, source.text].joined(separator: " "),
            confidence: min(source.confidence, target.confidence),
            boundingBox: source.boundingBox.union(target.boundingBox),
            status: target.status == .ignored ? source.status : target.status,
            role: target.role == .none ? source.role : target.role
        )

        editableOCRBlocks[targetIndex] = merged
        editableOCRBlocks.remove(at: sourceIndex)
    }

    func createLabeledCandidate() {
        let title = editableOCRBlocks
            .filter { $0.role == .title && $0.status != .ignored }
            .map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let author = editableOCRBlocks
            .filter { $0.role == .author && $0.status != .ignored }
            .map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return
        }

        addManualCandidate(title: title, author: author.isEmpty ? nil : author)
    }

    private func updateEditableBlocks(for state: OCRState) {
        guard case .completed(let result) = state else {
            editableOCRBlocks = []
            return
        }

        editableOCRBlocks = result.blocks.map { block in
            EditableOCRBlock(
                id: block.id,
                sourceBlockIDs: [block.id],
                text: block.text,
                confidence: block.confidence,
                boundingBox: block.boundingBox
            )
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
