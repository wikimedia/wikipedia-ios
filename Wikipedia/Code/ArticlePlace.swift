import UIKit
import WMF

class DebugAnnotation: MapAnnotation {
    public var title: String?
    public var subtitle: String?
    
    override func setup() {
        self.title = nil
        self.subtitle = nil
    }
}

class ArticlePlace: MapAnnotation {
    public var nextCoordinate: CLLocationCoordinate2D?
    public let title: String?
    public let subtitle: String?
    public let articles: [WMFArticle]
    public let identifier: Int
    
    init?(coordinate: CLLocationCoordinate2D, nextCoordinate: CLLocationCoordinate2D?, articles: [WMFArticle], identifier: Int) {
        self.title = nil
        self.subtitle = nil
        self.nextCoordinate = nextCoordinate
        self.articles = articles
        self.identifier = identifier
        super.init(coordinate: coordinate)
    }
    
    public static func identifierForArticles(articles: [WMFArticle]) -> Int {
        var hash = 0
        for article in articles {
            guard let key = article.key else {
                continue
            }
            hash ^= key.hash
        }
        return hash
    }
}
