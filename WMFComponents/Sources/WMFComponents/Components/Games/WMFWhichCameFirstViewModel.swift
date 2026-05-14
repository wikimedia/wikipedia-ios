import Foundation
import SwiftUI
import WMFData

@MainActor
public final class WMFWhichCameFirstViewModel: ObservableObject, Identifiable {

    enum Phase: Equatable {
        case loading
        case presenting
        case awaitingSubmission
        case revealing
        case transitioning
        case complete
        case error(String)
    }

    struct RevealState {
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

    private let date: String
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
        withAnimation(.easeInOut(duration: 0.18)) {
            showTitle = false
            showCardA = false
            showCardB = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(180))
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
            withAnimation(.spring(duration: 0.35)) { showTitle = true }
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.spring(duration: 0.4)) { showCardA = true }
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation(.spring(duration: 0.4)) { showCardB = true }
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
    var cardEvent: WMFOnThisDayCardEvent {
        WMFOnThisDayCardEvent(
            text: text,
            // todo Grey
            date: Date(),
            imageURL: pages.first?.thumbnail?.source
        )
    }
}

private extension WMFWhichCameFirstEvent {
    var cardEvent: WMFOnThisDayCardEvent {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"   // e.g. "May 13, 1969"
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone(identifier: "UTC")
        return WMFOnThisDayCardEvent(
            text: title,
            date: date,
            imageURL: thumbnailURL
        )
    }
}
