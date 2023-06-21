import Foundation

class WikiWrappedAPIResponse {

    class WikiWrappedArticle {
        
        class Topic {
            
            let name: String
            let weight: Int
            
            internal init(name: String, weight: Int) {
                self.name = name
                self.weight = weight
            }
        }
        
        let title: String
        let topics: [Topic]
        
        internal init(title: String, topics: [Topic]) {
            self.title = title
            self.topics = topics
        }
    }
    
    let articles: [WikiWrappedArticle]
    
    internal init(articles: [WikiWrappedAPIResponse.WikiWrappedArticle]) {
        self.articles = articles
    }
    
    static let mockResponse: WikiWrappedAPIResponse = {
        
        let topic1 = WikiWrappedArticle.Topic.init(name: "History and Society.Education", weight: 991)
        let topic2 = WikiWrappedArticle.Topic.init(name: "History and Society.Society", weight: 900)
        
        let topic3 = WikiWrappedArticle.Topic.init(name: "STEM.Space", weight: 991)
        let topic4 = WikiWrappedArticle.Topic.init(name: "STEM.Physics", weight: 900)
        
        let article1 = WikiWrappedArticle.init(title: "Barack Obama", topics: [topic1, topic2])
        let article2 = WikiWrappedArticle.init(title: "Space", topics: [topic3, topic4, topic1, topic2])
        
        return WikiWrappedAPIResponse(articles: [article1, article2])
    }()
}
