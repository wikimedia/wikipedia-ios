import Foundation
import SwiftUI
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFWhichCameFirstViewModel: ObservableObject, Identifiable {
    
    public enum Option: String, Codable {
        case a = "A"
        case b = "B"
    }

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
        public let footera11y: () -> String
        public let correctAnswerA11y: String
        public let incorrectAnswerA11y: String

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
            retryButton: String,
            footerA11y: @escaping () -> String,
            correctAnswerA11y: String,
            incorrectAnswerA11y: String
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
            self.footera11y = footerA11y
            self.correctAnswerA11y = correctAnswerA11y
            self.incorrectAnswerA11y = incorrectAnswerA11y
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
    @Published var cardViewModelA: WMFWhichCameFirstCardViewModel?
    @Published var cardViewModelB: WMFWhichCameFirstCardViewModel?
    @Published var revealState: RevealState?
    @Published var showTitle = false
    @Published var showCardA = false
    @Published var showCardB = false
    @Published var progressResults: [Bool?] = []

    public let date: String
    public lazy var localizedStrings: LocalizedStrings = WMFWhichCameFirstViewModel.LocalizedStrings(
        title: WMFLocalizedString("which-came-first-title", value: "Which came first?", comment: "Title prompt shown to the user during the Which Came First game"),
        submitButton: WMFLocalizedString("which-came-first-submit-button", value: "Submit", comment: "Button label to submit the user's selected answer in the Which Came First game"),
        nextButton: WMFLocalizedString("which-came-first-next-button", value: "Next", comment: "Button label to advance to the next question in the Which Came First game"),
        seeResultsButton: WMFLocalizedString("which-came-first-see-results-button", value: "See Results", comment: "Button label shown after the final question to view the game results"),
        correctFeedback: WMFLocalizedString("which-came-first-correct-feedback", value: "Correct!", comment: "Feedback message shown when the user answers correctly in the Which Came First game"),
        correctFeedback2: WMFLocalizedString("which-came-first-correct-feedback2", value: "+1 point", comment: "Feedback message shown when the user answers correctly in the Which Came First game"),
        incorrectFeedback: WMFLocalizedString("which-came-first-incorrect-feedback", value: "Incorrect", comment: "Feedback message shown when the user answers incorrectly in the Which Came First game"),
        gameCompleteTitle: "Game Complete!",
        perfectScoreMessage: "Perfect score!",
        niceWorkMessage: "Nice work! Come back tomorrow for a new game.",
        betterLuckMessage: "Better luck tomorrow!",
        errorTitle: WMFLocalizedString("which-came-first-error-title", value: "Something went wrong", comment: "Title shown on the error screen in the Which Came First game"),
        retryButton: WMFLocalizedString("which-came-first-retry-button", value: "Retry", comment: "Button label to retry loading the Which Came First game after an error"),
        footerA11y: footera11y,
        correctAnswerA11y: WMFLocalizedString("which-came-first-correct-answer-a11y", value: "Correct answer", comment: "Accessibility label indicating the correct answer on a card in the Which Came First game"),
        incorrectAnswerA11y: WMFLocalizedString("which-came-first-incorrect-answer-a11y", value: "Incorrect answer", comment: "Accessibility label indicating an incorrect answer on a card in the Which Came First game")
    )
        
    private func footera11y() -> String {
        let format = WMFLocalizedString("which-came-first-footer-a11y", value: "Question %1$d of %2$d", comment: "Accessibility label for the game progress indicator in the Which Came First game, where the first variable is the current question number and the second variable is the total number of questions")
        return String.localizedStringWithFormat(format, currentIndex + 1, totalQuestions)
    }
    
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

    public init(date: String, project: WMFProject) {
        self.date = date
        self.project = project
        self.dataController = WMFGamesDataController()
    }

    func load() {
        loadTask?.cancel()
        phase = .loading
        loadTask = Task {
            do {
                let (state, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(date: date, project: project)
                
                self.currentIndex = state.answers.count
                progressResults = Array(repeating: nil, count: state.questions.count)
                var recalculatedScore = 0
                for (index, question) in state.questions.enumerated() {
                    let key = question.id.uuidString
                    if let picked = state.answers[key] {
                        let isCorrect = picked == question.correctAnswer
                        if isCorrect { recalculatedScore += 1 }
                        progressResults[index] = isCorrect
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

    @Published var selectedOption: Option?

    func select(_ option: Option) {
        guard phase == .presenting || phase == .awaitingSubmission else { return }
        selectedOption = option
        cardViewModelA?.setSelected(option == .a)
        cardViewModelB?.setSelected(option == .b)
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
                    pickedOption: picked.rawValue
                )
                applyReveal(pickedOption: picked, correctOption: result.correctAnswer, isCorrect: result.isCorrect)
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }

    private func applyReveal(pickedOption: Option, correctOption: String, isCorrect: Bool) {
        if isCorrect { score += 1 }
        progressResults[currentIndex] = isCorrect
        cardViewModelA?.reveal(userSelected: pickedOption == .a, isCorrectAnswer: correctOption == "A")
        cardViewModelB?.reveal(userSelected: pickedOption == .b, isCorrectAnswer: correctOption == "B")
        revealState = RevealState(picked: pickedOption.rawValue, correct: correctOption, isCorrect: isCorrect)

        let announcement = isCorrect
            ? "\(localizedStrings.correctFeedback), \(localizedStrings.correctFeedback2)"
            : localizedStrings.incorrectFeedback
        UIAccessibility.post(notification: .announcement, argument: announcement)
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
        cardViewModelA = WMFWhichCameFirstCardViewModel(event: question.optionA.cardEvent)
        cardViewModelB = WMFWhichCameFirstCardViewModel(event: question.optionB.cardEvent)
    }

    deinit { loadTask?.cancel() }
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
