import UIKit
import SwiftUI
import WMFComponents

class TriviaGameCoordinator {
    private let navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme
    
    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
    }
    
    func start() {
        fetchTriviaData { [weak self] gameData in
            guard let self = self else { return }
            
            if let gameData = gameData {
                self.presentTriviaGame(with: gameData)
            } else {
                // Fallback with test events if no "On This Day" data is available
                self.presentFallbackGame()
            }
        }
    }
    
    private func fetchTriviaData(completion: @escaping (TriviaGameEvent?) -> Void) {
        // Extract data from the datastore
        guard let contentGroup = dataStore.viewContext.newestVisibleGroup(of: .onThisDay),
              let allEvents = contentGroup.fullContent?.object as? [WMFFeedOnThisDayEvent],
              allEvents.count >= 2,
              let midnightUTCDate = contentGroup.midnightUTCDate,
              let calendar = NSCalendar.wmf_utcGregorian() else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        let language = contentGroup.siteURL?.wmf_languageCode
        
        let ValidTriviaEvents = allEvents.compactMap { event -> (WMFFeedOnThisDayEvent, String)? in
            guard let year = event.year?.intValue else { return nil }
            
            var components = calendar.components([.month, .day], from: midnightUTCDate)
            components.year = year
            
            guard let date = calendar.date(from: components) else { return nil }
            
            let fullDateFormatter = DateFormatter.wmf_longDateGMTFormatter(for: language)
            let dateString = fullDateFormatter.string(from: date)
            
            return (event, dateString)
        }
        
        guard ValidTriviaEvents.count >= 2 else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        // Randomly select two different events
        let selectedEvents = Array(ValidTriviaEvents.shuffled().prefix(2))
        
        let gameData = TriviaGameEvent(
            firstEvent: selectedEvents[0].0.text ?? "",
            firstEventDate: selectedEvents[0].1,
            firstEventYear: selectedEvents[0].0.year?.intValue ?? 0,
            firstEventImageURL: selectedEvents[0].0.articlePreviews?.first?.thumbnailURL,
            secondEvent: selectedEvents[1].0.text ?? "",
            secondEventDate: selectedEvents[1].1,
            secondEventYear: selectedEvents[1].0.year?.intValue ?? 0,
            secondEventImageURL: selectedEvents[1].0.articlePreviews?.first?.thumbnailURL
        )
        
        DispatchQueue.main.async {
            completion(gameData)
        }
    }
    
    private func presentTriviaGame(with gameData: TriviaGameEvent) {
        let viewModel = TriviaGameSessionViewModel(gameData: gameData)
        let triviaView = TriviaGameView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: triviaView)
        navigationController.present(hostingController, animated: true)
    }
    
    private func presentFallbackGame() {
        let fallbackGameData = TriviaGameEvent(
            firstEvent: "U.S. figure skater Nancy Kerrigan is attacked and injured by an assailant hired by her rival Tonya Harding's ex-husband during the U.S. Figure Skating Championships.",
            firstEventDate: "January 6, 1994",
            firstEventYear: 1994,
            firstEventImageURL: nil,
            secondEvent: "Americans storm the United States Capitol Building to disrupt certification of the 2020 presidential election, resulting in five deaths and evacuation of the U.S. Congress.",
            secondEventDate: "January 6, 2021",
            secondEventYear: 2021,
            secondEventImageURL: nil
        )
        presentTriviaGame(with: fallbackGameData)
    }
}
