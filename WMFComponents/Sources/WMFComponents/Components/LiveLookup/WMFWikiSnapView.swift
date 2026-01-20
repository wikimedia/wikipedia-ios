import AVFoundation
import Vision
import SwiftUI

@available(iOS 18.0, *)
public struct WMFWikiSnapView: View {
    @SwiftUI.State private var classifications = [String]()
    @SwiftUI.State private var isClassifying = false
    @SwiftUI.State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    public init() {
        
    }
    
    public var body: some View {
        ZStack {
            // MARK: Full-screen background image
            Image("tomatoes")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // MARK: Overlay content
            VStack {
                topBar
                Spacer()
                centerContent
                Spacer()
            }
            .padding()
        }
    }
    
    private var topBar: some View {
        ZStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }

                Spacer()
            }

            Text("WikiSnap")
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
    
    private var centerContent: some View {
        VStack(spacing: 12) {
            Text("Related articles")
                .font(.title2)
                .fontWeight(.semibold)

            if isClassifying {
                ProgressView()
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else if classifications.isEmpty {
                Text("Point your camera at something")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(classifications, id: \.self) { result in
                    Text(result)
                        .font(.body)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
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
