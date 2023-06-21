import Foundation

public struct WikiWrappedViewModel {

    func getTopicCount(articles: [WikiWrappedAPIResponse.WikiWrappedArticle]) -> [String: Int] {

        var topics: [String] = []

        for article in articles {
            for topic in article.topics {
                if topic.name.contains("*") || topic.weight > 900 {
                    topics.append(topic.name)
                }
            }
        }

        let dictionary = topics.reduce(into: [:]) { counts, number in
            counts[number, default: 0] += 1
        }

        /*
        let orderedDict = (Array(dictionary).sorted { $0.1 < $1.1 })
        print(orderedDict)
         */
        
        return dictionary
    }

}
