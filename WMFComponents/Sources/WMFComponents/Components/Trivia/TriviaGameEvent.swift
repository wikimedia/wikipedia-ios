import Foundation

public struct TriviaGameEvent {
    public let firstEvent: String
    public let firstEventDate: String
    public let firstEventYear: Int
    public let firstEventImageURL: URL?
    public let secondEvent: String
    public let secondEventDate: String
    public let secondEventYear: Int
    public let secondEventImageURL: URL?
    
    public init(firstEvent: String, firstEventDate: String, firstEventYear: Int, firstEventImageURL: URL?, secondEvent: String, secondEventDate: String, secondEventYear: Int, secondEventImageURL: URL?) {
        self.firstEvent = firstEvent
        self.firstEventDate = firstEventDate
        self.firstEventYear = firstEventYear
        self.firstEventImageURL = firstEventImageURL
        self.secondEvent = secondEvent
        self.secondEventDate = secondEventDate
        self.secondEventYear = secondEventYear
        self.secondEventImageURL = secondEventImageURL
    }
}
