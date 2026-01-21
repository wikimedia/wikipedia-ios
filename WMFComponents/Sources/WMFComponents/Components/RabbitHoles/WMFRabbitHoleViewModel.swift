import Foundation
import SwiftUI
import WMFData

public final class WMFRabbitHoleViewModel: ObservableObject {

    @Published public var articles: [RabbitHoleArticle]

    public init(articles: [RabbitHoleArticle]) {
        self.articles = articles
    }
}

public struct RabbitHoleArticle: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let images: [URL]   // remote URLs, local file URLs, or asset URLs

    public init(title: String, images: [URL] = []) {
        self.title = title
        self.images = images
    }
}
