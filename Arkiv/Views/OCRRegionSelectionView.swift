import SwiftUI
import UIKit

struct OCRRegionSelectionView: View {
    let image: UIImage
    let selectedRegion: CGRect?
    let onRegionChanged: (CGRect?) -> Void

    @State private var dragStart: CGPoint?
    @State private var draftRegion: CGRect?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select a region to focus later")
                .font(.headline)

            GeometryReader { geometry in
                let imageRect = aspectFitRect(for: image.size, in: geometry.size)

                ZStack {
                    Color(.secondarySystemBackground)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)

                    if let region = draftRegion ?? selectedRegion {
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.16))
                            .overlay {
                                Rectangle()
                                    .stroke(Color.accentColor, lineWidth: 2)
                            }
                            .frame(
                                width: displayRect(for: region, in: imageRect).width,
                                height: displayRect(for: region, in: imageRect).height
                            )
                            .position(displayRect(for: region, in: imageRect).center)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            let start = dragStart ?? clamped(value.startLocation, to: imageRect)
                            dragStart = start

                            let current = clamped(value.location, to: imageRect)
                            let displaySelection = CGRect(
                                x: min(start.x, current.x),
                                y: min(start.y, current.y),
                                width: abs(current.x - start.x),
                                height: abs(current.y - start.y)
                            )

                            let normalized = normalizedRect(
                                from: displaySelection,
                                in: imageRect
                            )
                            draftRegion = normalized
                            onRegionChanged(normalized)
                        }
                        .onEnded { _ in
                            dragStart = nil
                            draftRegion = nil
                        }
                )
            }
            .aspectRatio(image.size, contentMode: .fit)

            HStack {
                Text(selectedRegion == nil ? "Drag across the image to select an area." : "Region selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if selectedRegion != nil {
                    Button("Clear") {
                        draftRegion = nil
                        onRegionChanged(nil)
                    }
                    .font(.caption.weight(.medium))
                }
            }
        }
    }

    private func aspectFitRect(for imageSize: CGSize, in container: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return .zero
        }

        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        return CGRect(
            x: (container.width - size.width) / 2,
            y: (container.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    private func displayRect(for normalized: CGRect, in imageRect: CGRect) -> CGRect {
        CGRect(
            x: imageRect.minX + normalized.minX * imageRect.width,
            y: imageRect.minY + (1 - normalized.maxY) * imageRect.height,
            width: normalized.width * imageRect.width,
            height: normalized.height * imageRect.height
        )
    }

    private func normalizedRect(from display: CGRect, in imageRect: CGRect) -> CGRect {
        guard imageRect.width > 0, imageRect.height > 0 else {
            return .zero
        }

        return CGRect(
            x: (display.minX - imageRect.minX) / imageRect.width,
            y: 1 - (display.maxY - imageRect.minY) / imageRect.height,
            width: display.width / imageRect.width,
            height: display.height / imageRect.height
        )
    }

    private func clamped(_ point: CGPoint, to rect: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, rect.minX), rect.maxX),
            y: min(max(point.y, rect.minY), rect.maxY)
        )
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
