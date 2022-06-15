import Foundation
import WMF

struct TalkPageResponse: Codable {
    let threads: TalkPageThreadItems?
    
    enum CodingKeys: String, CodingKey {
        case threads = "discussiontoolspageinfo"
    }
}

struct TalkPageThreadItems: Codable {
    let threadItems: [TalkPageItem]?
    
    enum CodingKeys: String, CodingKey {
        case threadItems = "threaditemshtml"
    }
    
    init(items: [TalkPageItem]) {
        self.threadItems = items
    }
}

struct TalkPageItem: Codable {
    let type: String?
    let level: Int?
    let id: String?
    let html: String?
    let headingLevel: Int?
    let placeholderHeading: Bool?
    let replies: [TalkPageItem]?
}

class TalkPageFetcher: Fetcher {
    
    func fetchTalkPageContent(url: URL, completion: @escaping (Result<TalkPageThreadItems, Error>) -> Void) {
        guard let talkPageURL = getTalkURL(url: url) else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        session.jsonDecodableTask(with: talkPageURL) { (result: TalkPageResponse?, response: URLResponse?, error: Error? ) in
            guard let result = result?.threads?.threadItems else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            let page = TalkPageThreadItems(items: result)
            completion(.success(page))
        }
    }
    
    func getTalkURL(url: URL) -> URL? {
        return url
    }
}
