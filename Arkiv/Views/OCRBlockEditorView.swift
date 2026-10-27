import SwiftUI

struct OCRBlockEditorView: View {
    let blocks: [EditableOCRBlock]
    let onTextChanged: (UUID, String) -> Void
    let onStatusChanged: (UUID, OCRBlockReviewStatus) -> Void
    let onRoleChanged: (UUID, OCRBlockRole) -> Void
    let onSplit: (UUID) -> Void
    let onCombine: (UUID, UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review OCR Blocks")
                .font(.headline)

            Text("Tap a block to confirm or ignore it. Edit text directly, or drag one block onto another to combine them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(blocks) { block in
                OCRBlockEditorRow(
                    block: block,
                    onTextChanged: { onTextChanged(block.id, $0) },
                    onStatusChanged: { onStatusChanged(block.id, $0) },
                    onRoleChanged: { onRoleChanged(block.id, $0) },
                    onSplit: { onSplit(block.id) },
                    onCombine: { onCombine($0, block.id) }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OCRBlockEditorRow: View {
    let block: EditableOCRBlock
    let onTextChanged: (String) -> Void
    let onStatusChanged: (OCRBlockReviewStatus) -> Void
    let onRoleChanged: (OCRBlockRole) -> Void
    let onSplit: () -> Void
    let onCombine: (UUID) -> Void

    @State private var draftText: String

    init(
        block: EditableOCRBlock,
        onTextChanged: @escaping (String) -> Void,
        onStatusChanged: @escaping (OCRBlockReviewStatus) -> Void,
        onRoleChanged: @escaping (OCRBlockRole) -> Void,
        onSplit: @escaping () -> Void,
        onCombine: @escaping (UUID) -> Void
    ) {
        self.block = block
        self.onTextChanged = onTextChanged
        self.onStatusChanged = onStatusChanged
        self.onRoleChanged = onRoleChanged
        self.onSplit = onSplit
        self.onCombine = onCombine
        _draftText = State(initialValue: block.text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(statusTitle) {
                    onStatusChanged(nextStatus)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(statusColor)

                Text("OCR \(block.confidence, format: .percent.precision(.fractionLength(0)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    Button("No Label") { onRoleChanged(.none) }
                    Button("Use as Title") { onRoleChanged(.title) }
                    Button("Use as Author") { onRoleChanged(.author) }
                } label: {
                    Label(roleTitle, systemImage: "tag")
                        .font(.caption.weight(.medium))
                }
            }

            TextEditor(text: $draftText)
                .frame(minHeight: 58, maxHeight: 120)
                .padding(6)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor.opacity(0.6), lineWidth: 1)
                }

            HStack {
                if block.text.contains("\n") {
                    Button("Split at Line Breaks", action: onSplit)
                        .font(.caption.weight(.medium))
                }

                Spacer()

                Image(systemName: "line.3.horizontal")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .contentShape(Rectangle())
                    .draggable(block.id.uuidString)
            }

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.08))
                .frame(height: 32)
                .overlay {
                    Label("Drop a block here to append it", systemImage: "arrow.down.to.line")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .dropDestination(for: String.self) { items, _ in
                    guard let sourceID = items.first.flatMap(UUID.init(uuidString:)), sourceID != block.id else {
                        return false
                    }

                    onCombine(sourceID)
                    return true
                }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        }
        .onChange(of: block.text) { _, newValue in
            if draftText != newValue {
                draftText = newValue
            }
        }
        .onChange(of: draftText) { _, newValue in
            if newValue != block.text {
                onTextChanged(newValue)
            }
        }
    }

    private var statusTitle: String {
        switch block.status {
        case .unreviewed: "Review"
        case .confirmed: "Confirmed"
        case .ignored: "Ignored"
        }
    }

    private var nextStatus: OCRBlockReviewStatus {
        switch block.status {
        case .unreviewed: .confirmed
        case .confirmed: .ignored
        case .ignored: .unreviewed
        }
    }

    private var statusColor: Color {
        switch block.status {
        case .unreviewed: .secondary
        case .confirmed: .green
        case .ignored: .red
        }
    }

    private var borderColor: Color {
        switch block.role {
        case .none: .secondary
        case .title: .blue
        case .author: .orange
        }
    }

    private var roleTitle: String {
        switch block.role {
        case .none: "Label"
        case .title: "Title"
        case .author: "Author"
        }
    }
}
