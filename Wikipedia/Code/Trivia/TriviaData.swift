import Foundation

class TriviaData {
    
    struct TriviaQuestion {
        let event: String
        let correctYear: String
        let incorrectYear: String
    }

    private let dataStore: MWKDataStore
    
    init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }

    func fetchTriviaQuestion(completion: @escaping (TriviaQuestion?) -> Void) {
        guard let contentGroup = dataStore.viewContext.newestVisibleGroup(of: .onThisDay),
              let events = contentGroup.contentPreview as? [WMFFeedOnThisDayEvent],
              let firstEvent = events.first,
              let year = firstEvent.year?.intValue else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        let eventText = firstEvent.text ?? "An important historical event occurred."
        let correctYear = String(year)
        let incorrectYear = String(year + Int.random(in: 1...50))
        
        let question = TriviaQuestion(
            event: eventText,
            correctYear: correctYear,
            incorrectYear: incorrectYear
        )
        
        DispatchQueue.main.async {
            completion(question)
        }
    }
}
