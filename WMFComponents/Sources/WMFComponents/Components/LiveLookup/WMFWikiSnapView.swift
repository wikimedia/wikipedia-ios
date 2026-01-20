import AVFoundation
import Vision
import SwiftUI

@available(iOS 18.0, *)
public struct WMFWikiSnapView: View {
    @SwiftUI.State private var classifications = [String]()
    @SwiftUI.State private var isClassifying = false
    @SwiftUI.State private var errorMessage: String?
    @SwiftUI.State private var wikiResults: [WikiResult] = []
    @Environment(\.dismiss) private var dismiss
    
    private let onArticleTap: (URL) -> Void
    
    public init(onArticleTap: @escaping (URL) -> Void) {
        self.onArticleTap = onArticleTap
    }
    
    public var body: some View {
        ZStack {
            // MARK: Full-screen background image
            Image("montreal")
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
            wikiResults = []
            
            guard let image = UIImage(named: "montreal") else {
                errorMessage = "Could not load image"
                isClassifying = false
                return
            }
            
            do {
                if let observations = try await classify(image) {
                    classifications = filterIdentifiers(from: observations)
                    
                    let topClassifications = Array(classifications.prefix(5))
                    for identifier in topClassifications {
                        if let result = try await fetchWikiSummary(for: identifier) {
                            wikiResults.append(result)
                        }
                    }
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
    
    // MARK: - Wikipedia API
    
    private func fetchWikiSummary(for searchTerm: String) async throws -> WikiResult? {
        let encoded = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? searchTerm
        let urlString = "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)"
        
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        let decoded = try JSONDecoder().decode(WikiSummaryResponse.self, from: data)
        return WikiResult(
            title: decoded.title,
            summary: decoded.extract,
            articleURL: decoded.contentUrls.desktop.page
        )
    }
}

// MARK: - Models

struct WikiResult: Identifiable {
    var id: String { title }
    let title: String
    let summary: String
    let articleURL: URL
}

struct WikiSummaryResponse: Decodable {
    let title: String
    let extract: String
    let contentUrls: ContentUrls
    
    enum CodingKeys: String, CodingKey {
        case title, extract
        case contentUrls = "content_urls"
    }
}

struct ContentUrls: Decodable {
    let desktop: DesktopUrl
}

struct DesktopUrl: Decodable {
    let page: URL
}
