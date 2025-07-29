import Foundation
import SwiftUI

public class TriviaGameSessionViewModel: ObservableObject {
    @Published public var hasAnswered: Bool = false
    @Published public var selectedFirst: Bool = false
    
    public let gameData: TriviaGameEvent

    public init(gameData: TriviaGameEvent) {
        self.gameData = gameData
    }

    public func selectEvent(isFirst: Bool) {
        guard !hasAnswered else { return }
        
        selectedFirst = isFirst
        hasAnswered = true
    }
    
    public func isCorrectChoice(isFirst: Bool) -> Bool {
        guard hasAnswered else { return false }
        
        let firstEventIsEarlier = gameData.firstEventYear < gameData.secondEventYear
        
        if isFirst {
            return firstEventIsEarlier
        } else {
            return !firstEventIsEarlier
        }
    }
}

