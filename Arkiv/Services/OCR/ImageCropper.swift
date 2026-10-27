import CoreGraphics
import UIKit

enum ImageCropper {
    static func crop(_ image: UIImage, to normalizedRegion: CGRect) throws -> UIImage {
        let normalizedImage = normalizeOrientation(of: image)
        guard let source = normalizedImage.cgImage else {
            throw ImageCropError.unsupportedImage
        }

        let region = normalizedRegion.standardized.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        let pixelRect = CGRect(
            x: region.minX * CGFloat(source.width),
            y: (1 - region.maxY) * CGFloat(source.height),
            width: region.width * CGFloat(source.width),
            height: region.height * CGFloat(source.height)
        ).integral

        guard pixelRect.width > 1, pixelRect.height > 1,
              let croppedImage = source.cropping(to: pixelRect) else {
            throw ImageCropError.invalidRegion
        }

        return UIImage(cgImage: croppedImage, scale: normalizedImage.scale, orientation: .up)
    }

    static func map(_ result: OCRResult, to originalRegion: CGRect) -> OCRResult {
        let blocks = result.blocks.map { block in
            let box = block.boundingBox
            let mappedBox = CGRect(
                x: originalRegion.minX + box.minX * originalRegion.width,
                y: originalRegion.minY + box.minY * originalRegion.height,
                width: box.width * originalRegion.width,
                height: box.height * originalRegion.height
            )

            return OCRTextBlock(
                id: block.id,
                text: block.text,
                confidence: block.confidence,
                boundingBox: mappedBox
            )
        }

        return OCRResult(fullText: result.fullText, blocks: blocks)
    }

    private static func normalizeOrientation(of image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}

private enum ImageCropError: LocalizedError {
    case unsupportedImage
    case invalidRegion

    var errorDescription: String? {
        switch self {
        case .unsupportedImage:
            "Arkiv could not prepare the selected region."
        case .invalidRegion:
            "The selected region is too small to recognize."
        }
    }
}
