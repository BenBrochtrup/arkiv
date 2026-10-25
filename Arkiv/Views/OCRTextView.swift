import SwiftUI

struct OCRTextView: View {
    let state: OCRState

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
