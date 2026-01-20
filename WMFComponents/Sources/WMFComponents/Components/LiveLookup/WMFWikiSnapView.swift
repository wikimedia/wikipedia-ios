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
        NavigationStack {
            Form {
                Section {
                    Image("montreal")
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
                } else if wikiResults.isEmpty && classifications.isEmpty {
                    Section {
                        Text("Image not classified yet")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ForEach(wikiResults) { result in
                            Button {
                                onArticleTap(result.articleURL)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(result.title)
                                        .font(.headline)
                                    Text(result.summary)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("This image contains:")
                    }
                }
            }
            .navigationTitle("WikiSnap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
