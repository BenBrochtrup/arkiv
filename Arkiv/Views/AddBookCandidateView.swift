import SwiftUI

struct AddBookCandidateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var author = ""

    let onSave: (String, String?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Book Details") {
                    TextField("Title", text: $title)
                    TextField("Author (optional)", text: $author)
                }
            }
            .navigationTitle("Add Book")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(title.trimmingCharacters(in: .whitespacesAndNewlines), normalizedAuthor)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var normalizedAuthor: String? {
        let value = author.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
