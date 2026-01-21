import Foundation
import SwiftUI
import WMFData

@MainActor
public class WMFRabbitHoleViewModel: ObservableObject {
    @Published var articles: [RabbitHoleArticle] = []
    @Published var isLoading = true
    
    private let urls: [URL]
    
    public init(urls: [URL]) {
        self.urls = urls
        Task {
            await fetchArticles()
        }
    }
    
    private func fetchArticles() async {
        isLoading = true
        
        articles = await withTaskGroup(of: (Int, RabbitHoleArticle?).self) { group in
            for (index, url) in urls.enumerated() {
                group.addTask {
                    let article = await self.fetchPageSummary(for: url)
                    return (index, article)
                }
            }
            
            var results: [(Int, RabbitHoleArticle?)] = []
            for await result in group {
                results.append(result)
            }
            
            return results
                .sorted { $0.0 < $1.0 }
                .compactMap { $0.1 }
        }
        
        isLoading = false
    }
    
    private func fetchPageSummary(for url: URL) async -> RabbitHoleArticle? {
        guard let title = url.wikipediaTitle else {
            return nil
        }
        
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        let summaryURLString = "https://en.wikipedia.org/api/rest_v1/page/summary/\(encodedTitle)"
        
        guard let summaryURL = URL(string: summaryURLString) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: summaryURL)
            let summary = try JSONDecoder().decode(PageSummary.self, from: data)
            
            var images: [URL] = []
            if let thumbnail = summary.thumbnail?.source, let thumbnailURL = URL(string: thumbnail) {
                images.append(thumbnailURL)
            }
            
            // Use the plain title, not displaytitle (which contains HTML)
            let cleanTitle = summary.title.replacingOccurrences(of: "_", with: " ")
            
            return RabbitHoleArticle(
                title: cleanTitle,
                images: images
            )
        } catch {
            print("Error fetching summary for \(title): \(error)")
            return nil
        }
    }
}

private struct PageSummary: Codable {
    let title: String
    let displaytitle: String?
    let thumbnail: ImageInfo?
    
    struct ImageInfo: Codable {
        let source: String
    }
}

private extension URL {
    /// Extracts the Wikipedia article title from a URL
    /// Handles formats like:
    /// - https://en.wikipedia.org/wiki/Cat
    /// - https://en.wikipedia.org/wiki/Schrödinger's_cat
    /// - https://en.m.wikipedia.org/wiki/Cat
    var wikipediaTitle: String? {
        // Check if this looks like a Wikipedia URL
        guard let host = host,
              host.contains("wikipedia.org") else {
            return nil
        }
        
        // Path should be like /wiki/Article_Title
        let pathComponents = pathComponents
        
        guard let wikiIndex = pathComponents.firstIndex(of: "wiki"),
              wikiIndex + 1 < pathComponents.count else {
            return nil
        }
        
        let rawTitle = pathComponents[wikiIndex + 1]
        
        // Decode percent encoding and replace underscores with spaces
        return rawTitle
            .removingPercentEncoding?
            .replacingOccurrences(of: "_", with: " ")
    }
    
    /// Returns the base Wikipedia site URL (e.g., https://en.wikipedia.org)
    var wikipediaSiteURL: URL? {
        guard let host = host,
              host.contains("wikipedia.org"),
              let scheme = scheme else {
            return nil
        }
        
        return URL(string: "\(scheme)://\(host)")
    }
}
