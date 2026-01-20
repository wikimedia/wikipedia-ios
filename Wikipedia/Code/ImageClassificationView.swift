import Vision
import SwiftUI

@available(iOS 18.0, *)
struct ImageClassifierView: View {
    
    @SwiftUI.State private var classifications = [String]()
    @SwiftUI.State private var isClassifying = false
    @SwiftUI.State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image("tomatoes") // Replace with your bundled image name
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .listRowInsets(EdgeInsets())
                }
                
                Section {
                    Button {
                        classifyImage()
                    } label: {
                        HStack {
                            Text("Classify Image")
                            if isClassifying {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isClassifying)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                } else if classifications.isEmpty {
                    Section {
                        Text("Image not classified yet")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ForEach(classifications, id: \.self) { result in
                            Text(result)
                        }
                    } header: {
                        Text("This image contains:")
                    }
                }
            }
            .navigationTitle("Image Classifier")
        }
    }
    
    private func classifyImage() {
        Task {
            isClassifying = true
            errorMessage = nil
            
            guard let image = UIImage(named: "tomatoes") else {
                errorMessage = "Could not load image"
                isClassifying = false
                return
            }
            
            do {
                if let observations = try await classify(image) {
                    classifications = filterIdentifiers(from: observations)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isClassifying = false
        }
    }
    
    private func classify(_ image: UIImage) async throws -> [ClassificationObservation]? {
        guard let ciImage = CIImage(image: image) else {
            return nil
        }
        
        let request = ClassifyImageRequest()
        return try await request.perform(on: ciImage)
    }
    
    private func filterIdentifiers(from observations: [ClassificationObservation]) -> [String] {
        observations
            .filter { $0.confidence > 0.1 }
            .map { $0.identifier }
    }
}
