import Foundation
import SwiftUI

class TriviaGameSessionViewModel: ObservableObject {
    enum GameState {
        case loading
        case question(TriviaData.TriviaQuestion)
        case answered(isCorrect: Bool)
    }

    @Published var gameState: GameState = .loading
    @Published var selectedAnswer: String? = nil

    private let dataController: TriviaData
    private var currentQuestion: TriviaData.TriviaQuestion?

    init(dataStore: MWKDataStore) {
        self.dataController = TriviaData(dataStore: dataStore)
        loadQuestion()
    }

    func loadQuestion() {
        gameState = .loading
        dataController.fetchTriviaQuestion { [weak self] question in
            guard let self = self,
            let question = question else { return }
            self.currentQuestion = question
            self.gameState = .question(question)
        }
    }

    func selectAnswer(_ answer: String) {
        guard case .question(let question) = gameState else { return }
        selectedAnswer = answer
        let isCorrect = (answer == question.correctYear)
        gameState = .answered(isCorrect: isCorrect)
    }

    var answerOptions: [String] {
        guard let question = currentQuestion else { return [] }
        return [question.correctYear, question.incorrectYear].shuffled()
    }

    var questionText: String {
        currentQuestion?.event ?? ""
    }
}
