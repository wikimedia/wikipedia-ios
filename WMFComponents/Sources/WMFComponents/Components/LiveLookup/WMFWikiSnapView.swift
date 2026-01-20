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
    @Environment(\.dismiss) private var dismiss
    
    private let onArticleTap: (URL) -> Void
    
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
                    Spacer()
                }
                .padding()
                .frame(width: geometry.size.width)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            classifyImage()
        }
    }
    
    private var foundArticle: some View {
        Text("")
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

            Spacer()
            
            
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
            } else if wikiResults.isEmpty {
                Text("Point your camera at something")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(wikiResults) { result in
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
                                            .foregroundStyle(.red)
                                    }
                                }
                                Text(result.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
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
                // Vision classification
                if let observations = try await classify(image) {
                    classifications = filterIdentifiers(from: observations)
                    
                    let topClassifications = Array(classifications.prefix(5))
                    for identifier in topClassifications {
                        if let result = try await fetchWikiSummary(for: identifier) {
                            wikiResults.append(result)
                        }
                    }
                }
                
                // Hardcoded: Montreal Olympic Stadium
                if let olympicStadium = try await fetchWikiSummary(for: "Olympic Stadium (Montreal)", isLocationBased: true) {
                    if !wikiResults.contains(where: { $0.title.lowercased() == olympicStadium.title.lowercased() }) {
                        wikiResults.append(olympicStadium)
                    }
                }
                
                // Location-based search fallback
                if let coordinates = imageCoordinates {
                    let nearbyPlaces = await searchNearbyPointsOfInterest(at: coordinates)
                    for place in nearbyPlaces.prefix(5) {
                        if let result = try await fetchWikiSummary(for: place, isLocationBased: true) {
                            if !wikiResults.contains(where: { $0.title.lowercased() == result.title.lowercased() }) {
                                wikiResults.append(result)
                            }
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
    
    private func fetchWikiSummary(for searchTerm: String, isLocationBased: Bool = false) async throws -> WikiResult? {
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
            isLocationBased: isLocationBased
        )
    }
}

// MARK: - Models

struct WikiResult: Identifiable {
    var id: String { title }
    let title: String
    let summary: String
    let articleURL: URL
    var isLocationBased: Bool = false
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
