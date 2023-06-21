import Foundation

public struct WikiWrappedViewModel {
    
    let title: NSAttributedString = {
        let string = "Recap[2023]"
        let attributedString = NSMutableAttributedString(string: string)

        attributedString.setAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)], range: NSRange(location: 0, length: string.count))
        
        attributedString.setAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10), NSAttributedString.Key.baselineOffset: 10], range: NSRange(location: 5, length: 6))
        
        return attributedString
    }()

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
