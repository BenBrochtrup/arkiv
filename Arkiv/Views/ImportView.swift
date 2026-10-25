import PhotosUI
import SwiftUI

struct ImportView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var viewModel: ImportViewModel

    init(textRecognizer: any ImageTextRecognizing = VisionTextRecognizer()) {
        _viewModel = State(initialValue: ImportViewModel(textRecognizer: textRecognizer))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Arkiv")
                            .font(.largeTitle.weight(.semibold))

                        Text("Find books mentioned in your screenshots.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Select Screenshot", systemImage: "photo")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoadingImage)

                    if viewModel.isLoadingImage {
                        ProgressView("Loading image…")
                    }

                    if let importError = viewModel.importError {
                        Text(importError)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    if let selectedImage = viewModel.selectedImage {
                        ImagePreview(image: selectedImage)
                    } else if !viewModel.isLoadingImage {
                        ContentUnavailableView(
                            "No Screenshot Selected",
                            systemImage: "photo.on.rectangle",
                            description: Text("Choose an image to begin.")
                        )
                    }

                    OCRTextView(state: viewModel.ocrState)
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.visible)
            .navigationBarTitleDisplayMode(.inline)
            .task(id: selectedItem) {
                guard let selectedItem else {
                    return
                }

                do {
                    let data = try await selectedItem.loadTransferable(type: Data.self)
                    await viewModel.loadImage(from: data)
                } catch is CancellationError {
                    return
                } catch {
                    viewModel.importError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ImportView()
}
