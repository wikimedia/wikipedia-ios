import Foundation
import SwiftUI
import WMFData

@MainActor
public final class WMFWhichCameFirstViewModel: ObservableObject, Identifiable {

    public struct LocalizedStrings {
        public let title: String
        public let submitButton: String
        public let nextButton: String
        public let seeResultsButton: String
        public let correctFeedback: String
        public let correctFeedback2: String
        public let incorrectFeedback: String
        public let gameCompleteTitle: String
        public let perfectScoreMessage: String
        public let niceWorkMessage: String
        public let betterLuckMessage: String
        public let errorTitle: String
        public let retryButton: String

        public init(
            title: String,
            submitButton: String,
            nextButton: String,
            seeResultsButton: String,
            correctFeedback: String,
            correctFeedback2: String,
            incorrectFeedback: String,
            gameCompleteTitle: String,
            perfectScoreMessage: String,
            niceWorkMessage: String,
            betterLuckMessage: String,
            errorTitle: String,
            retryButton: String
        ) {
            self.title = title
            self.submitButton = submitButton
            self.nextButton = nextButton
            self.seeResultsButton = seeResultsButton
            self.correctFeedback = correctFeedback
            self.incorrectFeedback = incorrectFeedback
            self.gameCompleteTitle = gameCompleteTitle
            self.perfectScoreMessage = perfectScoreMessage
            self.niceWorkMessage = niceWorkMessage
            self.betterLuckMessage = betterLuckMessage
            self.errorTitle = errorTitle
            self.retryButton = retryButton
            self.correctFeedback2 = correctFeedback2
        }
    }

    enum Phase: Equatable {
        case loading
        case presenting
        case awaitingSubmission
        case revealing
        case transitioning
        case complete
        case error(String)
    }

    struct RevealState: Equatable {
        let picked: String
        let correct: String
        let isCorrect: Bool
    }

    @Published var phase: Phase = .loading
    @Published var currentIndex: Int = 0
    @Published var score: Int = 0
    @Published var cardViewModelA: WMFOnThisDayCardViewModel?
    @Published var cardViewModelB: WMFOnThisDayCardViewModel?
    @Published var selectedOption: String?
    @Published var revealState: RevealState?
    @Published var showTitle = false
    @Published var showCardA = false
    @Published var showCardB = false
    @Published var progressResults: [Bool?] = []

    public let date: String
    public var localizedStrings: LocalizedStrings
    private let project: WMFProject
    private let dataController: WMFGamesDataController
    private var gameState: WMFWhichCameFirstGameState?
    private var sessionIdentifier: UUID?
    private var loadTask: Task<Void, Never>?

    var questions: [WMFWhichCameFirstQuestion] { gameState?.questions ?? [] }

    var currentQuestion: WMFWhichCameFirstQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var totalQuestions: Int { questions.count }

    public init(date: String, project: WMFProject, localizedStrings: LocalizedStrings) {
        self.date = date
        self.project = project
        self.localizedStrings = localizedStrings
        self.dataController = WMFGamesDataController()
    }

    func load() {
        loadTask?.cancel()
        phase = .loading
        loadTask = Task {
            do {
                let state = try await dataController.fetchOrStartWhichCameFirstDailySession(
                    date: date, project: project
                )
                self.gameState = state
                let sessions = try await dataController.fetchWhichCameFirstSessions(project: project)
                self.sessionIdentifier = sessions.first(where: { $0.dailyGameDate == date })?.identifier
                self.currentIndex = state.answers.count
                progressResults = Array(repeating: nil, count: state.questions.count)
                var recalculatedScore = 0
                for question in state.questions {
                    let key = question.id.uuidString
                    if let picked = state.answers[key] {
                        let isCorrect = picked == question.correctAnswer
                        if isCorrect { recalculatedScore += 1 }
                        if let index = state.questions.firstIndex(where: { $0.id == question.id }) {
                            progressResults[index] = isCorrect
                        }
                    }
                }
                self.score = recalculatedScore
                if currentIndex >= state.questions.count {
                    phase = .complete
                    return
                }
                rebuildCardViewModels()
                presentQuestion()
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }

    func select(_ option: String) {
        guard phase == .presenting || phase == .awaitingSubmission else { return }
        selectedOption = option
        cardViewModelA?.setSelected(option == "A")
        cardViewModelB?.setSelected(option == "B")
        phase = .awaitingSubmission
    }

    func submitSelectedAnswer() {
        guard let picked = selectedOption,
              let question = currentQuestion,
              let sessionID = sessionIdentifier else { return }
        phase = .revealing
        loadTask?.cancel()
        loadTask = Task {
            do {
                let result = try await dataController.submitWhichCameFirstAnswer(
                    sessionIdentifier: sessionID,
                    questionIdentifier: question.id,
                    pickedOption: picked
                )
                applyReveal(picked: picked, correct: result.correctAnswer, isCorrect: result.isCorrect)
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }

    func animateOutAndAdvance() {
        phase = .transitioning
        withAnimation(.easeInOut(duration: 0.75)) {
            showTitle = false
            showCardA = false
            showCardB = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(750))
            advanceInternal()
        }
    }

    private func advanceInternal() {
        guard let gameState else { return }
        let nextIndex = currentIndex + 1
        if nextIndex >= gameState.questions.count {
            phase = .complete
            return
        }
        currentIndex = nextIndex
        selectedOption = nil
        revealState = nil
        rebuildCardViewModels()
        presentQuestion()
    }

    private func presentQuestion() {
        phase = .presenting
        showTitle = false
        showCardA = false
        showCardB = false
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            withAnimation(.easeIn(duration: 0.75)) { showTitle = true }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(response: 0.75, dampingFraction: 0.8)) { showCardA = true }
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.spring(response: 0.75, dampingFraction: 0.8)) { showCardB = true }
        }
    }

    private func rebuildCardViewModels() {
        guard let question = currentQuestion else { return }
        cardViewModelA = WMFOnThisDayCardViewModel(event: question.optionA.cardEvent)
        cardViewModelB = WMFOnThisDayCardViewModel(event: question.optionB.cardEvent)
    }

    private func applyReveal(picked: String, correct: String, isCorrect: Bool) {
        if isCorrect { score += 1 }
        progressResults[currentIndex] = isCorrect
        cardViewModelA?.reveal(userSelected: picked == "A", isCorrectAnswer: correct == "A")
        cardViewModelB?.reveal(userSelected: picked == "B", isCorrectAnswer: correct == "B")
        revealState = RevealState(picked: picked, correct: correct, isCorrect: isCorrect)
    }

    deinit { loadTask?.cancel() }
}


public extension WMFOnThisDayEvent {
    func cardEvent(month: Int, day: Int) -> WMFOnThisDayCardEvent {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let date = Calendar(identifier: .gregorian).date(from: components) ?? Date()
        return WMFOnThisDayCardEvent(
            text: text,
            date: date,
            imageURL: pages.first?.thumbnail?.source
        )
    }
}

private extension WMFWhichCameFirstEvent {
    var cardEvent: WMFOnThisDayCardEvent {
        return WMFOnThisDayCardEvent(
            text: title,
            date: date,
            imageURL: thumbnailURL
        )
    }
}
