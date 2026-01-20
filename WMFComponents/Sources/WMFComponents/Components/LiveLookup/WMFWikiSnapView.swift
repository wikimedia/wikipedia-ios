import AVFoundation
import Vision
import SwiftUI
import MapKit

@available(iOS 18.0, *)
public struct WMFWikiSnapView: View {
    @SwiftUI.State private var classifications = [String]()
    @SwiftUI.State private var isClassifying = false
    @SwiftUI.State private var errorMessage: String?
    @SwiftUI.State private var wikiResults: [WikiResult] = []
    @SwiftUI.State private var shareURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    private let onArticleTap: (URL) -> Void
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    // Hardcoded coordinates (Montreal Olympic Stadium area)
    private let imageCoordinates: CLLocationCoordinate2D? = CLLocationCoordinate2D(
        latitude: 45.558,
        longitude: -73.552
    )
    
    public init(onArticleTap: @escaping (URL) -> Void) {
        self.onArticleTap = onArticleTap
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: Full-screen background image
                Image("montreal")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // MARK: Overlay content
                VStack {
                    topBar
                    Spacer()
                    centerContent
                }
                .frame(height: .infinity)
                .padding()
                .frame(width: geometry.size.width)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            classifyImage()
        }
        .sheet(item: $shareURL) { url in
            ShareSheet(activityItems: [url])
        }
    }
    
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("X")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            
            Text("WikiSnap")
                .font(.title)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
    
    private var centerContent: some View {
        VStack(spacing: 12) {
            if isClassifying {
                ProgressView()
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else if wikiResults.isEmpty {
                Text("Point your camera at something")
                    .foregroundStyle(.secondary)
            } else {
                // First result (featured)
                if let result = wikiResults.first {
                    HStack(spacing: 0) {
                        Button {
                            onArticleTap(result.articleURL)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(result.title)
                                            .font(.headline)
                                        if result.isLocationBased {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundStyle(Color(uiColor: WMFColor.blue700))
                                        }
                                        if let confidence = result.confidence {
                                            Text("\(Int(confidence * 100))%")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Text(result.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            shareURL = result.articleURL
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                        .buttonStyle(.plain)
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                
                Text("Related articles")
                    .font(Font((WMFFont.for(.semiboldCaption1))))
                    .foregroundStyle(Color(uiColor: theme.paperBackground))
                
                // Remaining results
                ForEach(wikiResults.dropFirst()) { result in
                    HStack(spacing: 0) {
                        Button {
                            onArticleTap(result.articleURL)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(result.title)
                                            .font(.headline)
                                        if result.isLocationBased {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundStyle(Color(uiColor: WMFColor.blue700))
                                        }
                                        if let confidence = result.confidence {
                                            Text("\(Int(confidence * 100))%")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Text(result.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .padding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            shareURL = result.articleURL
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                        .buttonStyle(.plain)
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
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
                // Vision classification
                if let observations = try await classify(image) {
                    let filtered = observations.filter { $0.confidence > 0.1 }
                    
                    for observation in filtered.prefix(5) {
                        if let result = try await fetchWikiSummary(for: observation.identifier, confidence: observation.confidence) {
                            wikiResults.append(result)
                        }
                    }
                }
                
                self.wikiResults = Array(wikiResults.prefix(4))
                
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
    
    // MARK: - MapKit Search
    
    private func searchNearbyPointsOfInterest(at coordinate: CLLocationCoordinate2D) async -> [String] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "landmark"
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )
        request.resultTypes = .pointOfInterest
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            return response.mapItems.compactMap { $0.name }
        } catch {
            print("MapKit search error: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Wikipedia API
    
    private func fetchWikiSummary(for searchTerm: String, isLocationBased: Bool = false, confidence: Float? = nil) async throws -> WikiResult? {
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
            articleURL: decoded.contentUrls.desktop.page,
            isLocationBased: isLocationBased,
            confidence: confidence
        )
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - URL + Identifiable

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Models

struct WikiResult: Identifiable {
    var id: String { title }
    let title: String
    let summary: String
    let articleURL: URL
    var isLocationBased: Bool = false
    var confidence: Float?
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
