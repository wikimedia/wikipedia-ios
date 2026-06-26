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
    }

    @Published var phase: Phase = .loading
    @Published var currentIndex: Int = 0
    @Published public var score: Int = 0
    @Published var cardViewModelA: WMFWhichCameFirstCardViewModel?
    @Published var cardViewModelB: WMFWhichCameFirstCardViewModel?
    @Published var revealState: RevealState?
    @Published var showTitle = false
    @Published var showCardA = false
    @Published var showCardB = false
    @Published var progressResults: [Bool?] = []

    public private(set) var date: String
    public lazy var localizedStrings: LocalizedStrings = WMFWhichCameFirstViewModel.LocalizedStrings(
        title: WMFLocalizedString("which-came-first-title", value: "Which came first?", comment: "Title prompt shown to the user during the Which Came First game"),
        submitButton: WMFLocalizedString("which-came-first-submit-button", value: "Submit", comment: "Button label to submit the user's selected answer in the Which Came First game"),
        nextButton: WMFLocalizedString("which-came-first-next-button", value: "Next", comment: "Button label to advance to the next question in the Which Came First game"),
        seeResultsButton: WMFLocalizedString("which-came-first-see-results-button", value: "See Results", comment: "Button label shown after the final question to view the game results"),
        correctFeedback: WMFLocalizedString("which-came-first-correct-feedback", value: "Correct!", comment: "Feedback message shown when the user answers correctly in the Which Came First game"),
        correctFeedback2: WMFLocalizedString("which-came-first-correct-feedback2", value: "+1 point", comment: "Feedback message shown when the user answers correctly in the Which Came First game"),
        incorrectFeedback: WMFLocalizedString("which-came-first-incorrect-feedback", value: "Incorrect!", comment: "Feedback message shown when the user answers incorrectly in the Which Came First game"),
        gameCompleteTitle: WMFLocalizedString("which-came-first-game-complete-title", value: "Game Complete!", comment: "Title shown when the user has completed all questions in the Which Came First game"),
        perfectScoreMessage: WMFLocalizedString("which-came-first-perfect-score", value: "Perfect score!", comment: "Message shown when the user answers all questions correctly in the Which Came First game"),
        niceWorkMessage: WMFLocalizedString("which-came-first-nice-work", value: "Nice work! Come back tomorrow for a new game.", comment: "Message shown when the user scores above half in the Which Came First game"),
        betterLuckMessage: WMFLocalizedString("which-came-first-better-luck", value: "Better luck tomorrow!", comment: "Message shown when the user scores half or below in the Which Came First game"),
        errorTitle: WMFLocalizedString("which-came-first-error-title", value: "Something went wrong", comment: "Title shown on the error screen in the Which Came First game"),
        retryButton: WMFLocalizedString("which-came-first-retry-button", value: "Retry", comment: "Button label to retry loading the Which Came First game after an error"),
        footerA11y: footera11y,
        correctAnswerA11y: WMFLocalizedString("which-came-first-correct-answer-a11y", value: "Correct answer", comment: "Accessibility label indicating the correct answer on a card in the Which Came First game"),
        incorrectAnswerA11y: WMFLocalizedString("which-came-first-incorrect-answer-a11y", value: "Incorrect answer", comment: "Accessibility label indicating an incorrect answer on a card in the Which Came First game")
    )
        
    private func footera11y() -> String {
        let format = WMFLocalizedString("which-came-first-footer-a11y", value: "Question %1$d of %2$d", comment: "Accessibility label for the game progress indicator in the Which Came First game, where $1 is the current question number and the $2 is the total number of questions")
        return String.localizedStringWithFormat(format, currentIndex + 1, totalQuestions)
    }

    // MARK: - Navigation Callbacks

    public var didTapShare: (@MainActor @Sendable () -> Void)?
    public var onArticleTap: WMFWhichCameFirstArticlesViewModel.ArticleTapAction?
    public var onArticleOpenInNewTab: WMFWhichCameFirstArticlesViewModel.ArticleTapAction?
    public var onArticleOpenInBackgroundTab: WMFWhichCameFirstArticlesViewModel.ArticleTapAction?
    public var onArticleSaveForLater: WMFWhichCameFirstArticlesViewModel.ArticleTapAction?
    public var onArticleUnsave: WMFWhichCameFirstArticlesViewModel.ArticleTapAction?
    public var onCheckSavedState: ((URL) -> Bool)?
    public var onArticleShare: WMFWhichCameFirstArticlesViewModel.ArticleShareAction?
    public var onArticleTapToEvent: WMFWhichCameFirstArticlesViewModel.ArticleEventTapAction?
    public var didTapLearnMore: (@MainActor @Sendable () -> Void)?
    public var didTapReportProblem: (@MainActor @Sendable () -> Void)?
    public var onPlayArchive: (@MainActor @Sendable () -> Void)?
    public var onDateChanged: (@MainActor @Sendable () -> Void)?

    // MARK: - Instrumentation Callbacks

    /// Slide becomes visible. Index is 1-based (game_play_1 … game_play_5).
    public var didImpressionSlide: (@MainActor @Sendable (_ slideIndex: Int) -> Void)?
    /// Taps the exit button during gameplay. Index is 1-based.
    public var didTapExitDuringPlay: (@MainActor @Sendable (_ slideIndex: Int, _ isComplete: Bool) -> Void)?
    /// Taps Submit on a question. Index is 1-based.
    public var didSubmitAnswer: (@MainActor @Sendable (_ slideIndex: Int) -> Void)?
    /// Last question is answered and the game transitions to complete.
    public var didFinishGame: (@MainActor @Sendable () -> Void)?

    public func makeShareArticleEvents() -> [(event: WMFWhichCameFirstEvent, project: WMFProject)]? {
        guard let state = gameState else { return nil }
        return state.questions.compactMap { question in
            guard let event = selectedEvent(from: question) else { return nil }
            return (event: event, project: project)
        }
    }

    public func makeShareQuestionResults() -> [Bool]? {
        guard !progressResults.isEmpty else { return nil }
        return progressResults.map { $0 ?? false }
    }
    
    public var isGameInProgress: Bool {
        if case .error = phase { return false }
        return phase != .complete && phase != .loading
    }

    private func selectedEvent(from question: WMFWhichCameFirstQuestion) -> WMFWhichCameFirstEvent? {
        let a = question.optionA
        let b = question.optionB
        let aHasImage = a.thumbnailURL != nil
        let bHasImage = b.thumbnailURL != nil

        switch (aHasImage, bHasImage) {
        case (true, false):
            return a
        case (false, true):
            return b
        default:
            return Bool.random() ? a : b
        }
    }

    public let project: WMFProject
    private let dataController: WMFGamesDataController
    private var gameState: WMFWhichCameFirstGameState?
    private var sessionIdentifier: UUID?
    private var loadTask: Task<Void, Never>?
    private var animationTask: Task<Void, Never>?

    /// Guards `load()` so it only runs once per game presentation, and  `viewWillAppear` doesn't reload the game everytime
    private var hasLoaded = false
    
    @Published public var isLoggedIn: Bool = false
    public var onLogIn: (@MainActor @Sendable () -> Void)?

    var questions: [WMFWhichCameFirstQuestion] { gameState?.questions ?? [] }

    var currentQuestion: WMFWhichCameFirstQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    public var totalQuestions: Int { questions.count }

    public init(date: String, project: WMFProject) {
        self.date = date
        self.project = project
        self.dataController = WMFGamesDataController()
    }

    // MARK: - Archive reload

    /// Reloads the game with a different date, e.g. when the user picks a date
    /// from the archive. Cancels any in-flight work, resets all state, then
    /// triggers a fresh load as if the view model were brand-new.
    public func reload(with newDate: String) {
        loadTask?.cancel()
        animationTask?.cancel()
        date = newDate
        hasLoaded = false
        gameState = nil
        sessionIdentifier = nil
        currentIndex = 0
        score = 0
        progressResults = []
        selectedOption = nil
        revealState = nil
        cardViewModelA = nil
        cardViewModelB = nil
        showTitle = false
        showCardA = false
        showCardB = false
        phase = .loading
        load()
        onDateChanged?()
    }

    func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        loadTask?.cancel()
        animationTask?.cancel()
        phase = .loading
        loadTask = Task {
            do {
                let (state, sessionID) = try await dataController.fetchOrStartWhichCameFirstDailySession(date: date, project: project)
                
                self.gameState = state
                self.sessionIdentifier = sessionID
                
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
                    showTitle = false
                    return
                }
                rebuildCardViewModels()
                presentQuestion()
            } catch {
                hasLoaded = false
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

        didSubmitAnswer?(currentIndex + 1)

        phase = .revealing
        loadTask?.cancel()
        loadTask = Task {
            do {
                _ = try await dataController.submitWhichCameFirstAnswer(
                    sessionIdentifier: sessionID,
                    questionIdentifier: question.id,
                    pickedOption: picked.rawValue
                )
                applyReveal(pickedOption: picked, correctOption: Option(rawValue: question.correctAnswer) ?? .a)
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }

    private func applyReveal(pickedOption: Option, correctOption: Option) {
        let isCorrect = pickedOption == correctOption
        if isCorrect { score += 1 }
        progressResults[currentIndex] = isCorrect
        cardViewModelA?.reveal(userSelected: pickedOption == .a, isCorrectAnswer: correctOption == .a)
        cardViewModelB?.reveal(userSelected: pickedOption == .b, isCorrectAnswer: correctOption == .b)
        revealState = RevealState(picked: pickedOption.rawValue, correct: correctOption.rawValue)

        let announcement = isCorrect
            ? "\(localizedStrings.correctFeedback), \(localizedStrings.correctFeedback2)"
            : localizedStrings.incorrectFeedback

        Task { [weak self] in
            guard self != nil else { return }
            try? await Task.sleep(for: .milliseconds(500))
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
    
    func animateOutAndAdvance() {
        phase = .transitioning
        withAnimation(.easeInOut(duration: 0.75)) {
            showTitle = false
            showCardA = false
            showCardB = false
        }
        animationTask?.cancel()
        animationTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(750))
            self?.advanceInternal()
        }
    }

    private func advanceInternal() {
        guard let gameState else { return }
        let nextIndex = currentIndex + 1
        if nextIndex >= gameState.questions.count {
            phase = .complete
            didFinishGame?()
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

        didImpressionSlide?(currentIndex + 1)

        animationTask?.cancel()
        animationTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(50))
            withAnimation(.easeIn(duration: 0.75)) { self.showTitle = true }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(response: 0.75, dampingFraction: 0.8)) { self.showCardA = true }
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.spring(response: 0.75, dampingFraction: 0.8)) { self.showCardB = true }
        }
    }

    private func rebuildCardViewModels() {
        guard let question = currentQuestion else { return }
        cardViewModelA = WMFWhichCameFirstCardViewModel(event: question.optionA.cardEvent)
        cardViewModelB = WMFWhichCameFirstCardViewModel(event: question.optionB.cardEvent)
    }

    deinit {
        loadTask?.cancel()
        animationTask?.cancel()
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
