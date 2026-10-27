import SwiftUI

struct OCRTextView: View {
    let state: OCRState
    let blocks: [EditableOCRBlock]
    let onTextChanged: @MainActor @Sendable (UUID, String) -> Void
    let onStatusChanged: @MainActor @Sendable (UUID, OCRBlockReviewStatus) -> Void
    let onRoleChanged: @MainActor @Sendable (UUID, OCRBlockRole) -> Void
    let onSplit: @MainActor @Sendable (UUID) -> Void
    let onCombine: @MainActor @Sendable (UUID, UUID) -> Void

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .recognizing:
            ProgressView("Recognizing text…")
        case .noText:
            ContentUnavailableView(
                "No Text Found",
                systemImage: "text.magnifyingglass",
                description: Text("Arkiv could not find readable text in this image.")
            )
        case .completed(let result):
            VStack(alignment: .leading, spacing: 8) {
                Text("Recognized Text")
                    .font(.headline)

                Text("\(result.blocks.count) lines recognized")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView {
                    Text(result.fullText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding()
                }
                .frame(height: 220)
                .scrollIndicators(.visible)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                OCRBlockEditorView(
                    blocks: blocks,
                    onTextChanged: onTextChanged,
                    onStatusChanged: onStatusChanged,
                    onRoleChanged: onRoleChanged,
                    onSplit: onSplit,
                    onCombine: onCombine
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .failed(let message):
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }
}
