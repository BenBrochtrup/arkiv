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
                        OCRRegionSelectionView(
                            image: selectedImage,
                            selectedRegion: viewModel.ocrSelection.region,
                            onRegionChanged: viewModel.updateSelectedRegion
                        )

                        if viewModel.ocrSelection.region != nil {
                            Button {
                                Task {
                                    await viewModel.recognizeSelectedRegion()
                                }
                            } label: {
                                Label("Recognize Selected Region", systemImage: "text.viewfinder")
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isProcessingRegion || viewModel.isLoadingImage)

                            if viewModel.isProcessingRegion {
                                ProgressView("Recognizing selected region…")
                            }
                        }
                    } else if !viewModel.isLoadingImage {
                        ContentUnavailableView(
                            "No Screenshot Selected",
                            systemImage: "photo.on.rectangle",
                            description: Text("Choose an image to begin.")
                        )
                    }

                    if viewModel.isShowingFocusedOCR {
                        Button("Show Full Image OCR", action: viewModel.showFullImageOCR)
                            .font(.subheadline.weight(.medium))
                    }

                    OCRTextView(
                        state: viewModel.ocrState,
                        blocks: viewModel.editableOCRBlocks,
                        onTextChanged: viewModel.updateOCRBlockText,
                        onStatusChanged: viewModel.updateOCRBlockStatus,
                        onRoleChanged: viewModel.updateOCRBlockRole,
                        onSplit: viewModel.splitOCRBlock,
                        onCombine: viewModel.combineOCRBlocks
                    )

                    if case .completed = viewModel.ocrState {
                        Button("Create Candidate From Labels", action: viewModel.createLabeledCandidate)
                            .buttonStyle(.bordered)
                    }

                    if viewModel.selectedImage != nil {
                        CandidateListView(
                            candidates: viewModel.candidates,
                            onAdd: viewModel.addManualCandidate
                        )
                    }
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
