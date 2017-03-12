import UIKit
import MapKit
import WMF

class DebugAnnotation: NSObject, MKAnnotation {
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?
    
    
    init?(coordinate: CLLocationCoordinate2D) {
        self.title = nil
        self.subtitle = nil
        self.coordinate = coordinate
    }
}

class ArticlePlace: NSObject, MKAnnotation {
    public dynamic var coordinate: CLLocationCoordinate2D
    public var nextCoordinate: CLLocationCoordinate2D?
    public let title: String?
    public let subtitle: String?
    public let articles: [WMFArticle]
    public let identifier: String
    
    init?(coordinate: CLLocationCoordinate2D, nextCoordinate: CLLocationCoordinate2D?, articles: [WMFArticle], identifier: String) {
        self.title = nil
        self.subtitle = nil
        self.coordinate = coordinate
        self.nextCoordinate = nextCoordinate
        self.articles = articles
        self.identifier = identifier
    }
    
    public static func identifierForArticles(articles: [WMFArticle]) -> String {
        return articles.map({ (article) -> Int in
            guard let key = article.key else {
                return 0
            }
            return key.hash
        }).sorted().reduce("|") { (result, hash) -> String in
            return result + "\(hash)|"
        }
    }
}
