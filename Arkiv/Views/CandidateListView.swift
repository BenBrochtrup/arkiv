import SwiftUI

struct CandidateListView: View {
    let candidates: [BookCandidate]
    let onAdd: (String, String?) -> Void

    @State private var isShowingAddCandidate = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Candidate Suggestions")
                    .font(.headline)

                Spacer()

                Button("Add Book", systemImage: "plus") {
                    isShowingAddCandidate = true
                }
                .font(.subheadline.weight(.medium))
            }

            if candidates.isEmpty {
                Text("No automatic candidates identified yet. Add or label a book manually.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(candidates) { candidate in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(candidate.title)
                            .font(.body.weight(.medium))

                        if let author = candidate.author {
                            Text(author)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text(candidate.evidence.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isShowingAddCandidate) {
            AddBookCandidateView(onSave: onAdd)
        }
    }
}
