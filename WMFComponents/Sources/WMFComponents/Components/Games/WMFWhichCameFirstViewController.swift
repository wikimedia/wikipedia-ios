import UIKit
import SwiftUI
import WMFData

// TODO: FINAL UI (T423933)

// MARK: - View Model

@MainActor
public final class WMFWhichCameFirstViewModel: ObservableObject {

    // MARK: - Nested Types

    enum Phase {
        case loading
        case question
        case feedback(isCorrect: Bool, correctAnswer: String)
        case complete
        case error(String)
    }

    // MARK: - Published

    @Published var phase: Phase = .loading
    @Published var currentIndex: Int = 0
    @Published var score: Int = 0
    @Published var cardViewModelA: WMFOnThisDayCardViewModel?
    @Published var cardViewModelB: WMFOnThisDayCardViewModel?

    // MARK: - Private

    private let date: String
    private let project: WMFProject
    private let dataController: WMFGamesDataController
    private var gameState: WMFWhichCameFirstGameState?
    private var sessionIdentifier: UUID?
    private var loadTask: Task<Void, Never>?

    // MARK: - Computed

    var questions: [WMFWhichCameFirstQuestion] {
        gameState?.questions ?? []
    }

    var currentQuestion: WMFWhichCameFirstQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var totalQuestions: Int { questions.count }

    // MARK: - Init

    public init(date: String, project: WMFProject) {
        self.date = date
        self.project = project
        self.dataController = WMFGamesDataController()
    }

    // MARK: - Public

    func load() {
        loadTask?.cancel()
        loadTask = Task {
            do {
                let state = try await dataController.fetchOrStartWhichCameFirstDailySession(date: date, project: project)
                self.gameState = state
                self.currentIndex = state.answers.count  // resume where we left off
                self.score = state.answers.values.filter { _ in true }.count  // will recalc via submit results

                // Recalculate score from stored answers
                var recalcScore = 0
                for question in state.questions {
                    let key = question.id.uuidString
                    if let picked = state.answers[key], picked == question.correctAnswer {
                        recalcScore += 1
                    }
                }
                self.score = recalcScore

                if state.answers.count >= state.questions.count {
                    self.phase = .complete
                } else {
                    self.rebuildCardViewModels()
                    self.phase = .question
                }
            } catch {
                self.phase = .error(error.localizedDescription)
            }
        }
    }

    func submitAnswer(_ picked: String) {
        guard let question = currentQuestion,
              gameState != nil else { return }

        loadTask?.cancel()
        loadTask = Task {
            do {
                // Need session identifier — fetch the session to get its UUID
                if sessionIdentifier == nil {
                    sessionIdentifier = try await fetchSessionIdentifier()
                }
                guard let sessionID = sessionIdentifier else { return }

                let result = try await dataController.submitWhichCameFirstAnswer(
                    sessionIdentifier: sessionID,
                    questionIdentifier: question.id,
                    pickedOption: picked
                )
                if result.isCorrect {
                    self.score += 1
                }
                self.applyFeedback(isCorrect: result.isCorrect, correctAnswer: result.correctAnswer)
                self.phase = .feedback(isCorrect: result.isCorrect, correctAnswer: result.correctAnswer)
            } catch {
                self.phase = .error(error.localizedDescription)
            }
        }
    }

    func advance() {
        guard let state = gameState else { return }
        let nextIndex = currentIndex + 1
        if nextIndex >= state.questions.count {
            self.phase = .complete
        } else {
            self.currentIndex = nextIndex
            self.rebuildCardViewModels()
            self.phase = .question
        }
    }

    // MARK: - Private

    private func rebuildCardViewModels() {
        guard let question = currentQuestion else { return }
        cardViewModelA = WMFOnThisDayCardViewModel(event: question.optionA.onThisDayEvent)
        cardViewModelB = WMFOnThisDayCardViewModel(event: question.optionB.onThisDayEvent)
    }

    private func applyFeedback(isCorrect: Bool, correctAnswer: String) {
        cardViewModelA?.reveal(correct: correctAnswer == "A")
        cardViewModelB?.reveal(correct: correctAnswer == "B")
    }

    private func fetchSessionIdentifier() async throws -> UUID? {
        let sessions = try await dataController.fetchWhichCameFirstSessions(project: project)
        return sessions.first(where: { $0.dailyGameDate == date })?.identifier
    }

    deinit {
        loadTask?.cancel()
    }
}

// MARK: - Hosting Controller

public final class WMFWhichCameFirstHostingController: WMFComponentHostingController<WMFWhichCameFirstView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFWhichCameFirstViewModel

    public init(viewModel: WMFWhichCameFirstViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFWhichCameFirstView(viewModel: viewModel))
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        viewModel.load()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: "Which Came First?",
            customView: nil,
            alignment: .centerCompact
        )
        let closeConfig = WMFLargeCloseButtonConfig(
            imageType: .plainX,
            target: self,
            action: #selector(tappedClose),
            alignment: .leading
        )
        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
    }

    @objc private func tappedClose() {
        dismiss(animated: true)
    }
}

// MARK: - SwiftUI View

public struct WMFWhichCameFirstView: View {

    @ObservedObject var viewModel: WMFWhichCameFirstViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme { appEnvironment.theme }

    public var body: some View {
        Group {
            switch viewModel.phase {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .question:
                if let question = viewModel.currentQuestion {
                    questionView(question: question)
                }

            case .feedback(let isCorrect, let correctAnswer):
                if let question = viewModel.currentQuestion {
                    feedbackView(question: question, isCorrect: isCorrect, correctAnswer: correctAnswer)
                }

            case .complete:
                completeView()

            case .error(let message):
                errorView(message: message)
            }
        }
        .background(Color(uiColor: theme.paperBackground))
    }

    // MARK: - Question

    private func questionView(question: WMFWhichCameFirstQuestion) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                progressHeader()

                Text("Which came first?")
                    .font(Font(WMFFont.for(.semiboldHeadline)))
                    .foregroundColor(Color(uiColor: theme.text))
                    .multilineTextAlignment(.center)

                if let cardA = viewModel.cardViewModelA {
                    WMFOnThisDayCardView(viewModel: cardA)
                        .onTapGesture {
                            cardA.toggleSelection()
                            viewModel.submitAnswer("A")
                        }
                }

                if let cardB = viewModel.cardViewModelB {
                    WMFOnThisDayCardView(viewModel: cardB)
                        .onTapGesture {
                            cardB.toggleSelection()
                            viewModel.submitAnswer("B")
                        }
                }

                Spacer(minLength: 24)
            }
            .padding()
        }
    }

    // MARK: - Feedback

    private func feedbackView(question: WMFWhichCameFirstQuestion, isCorrect: Bool, correctAnswer: String) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                progressHeader()

                Text(isCorrect ? "✓ Correct!" : "✗ Incorrect")
                    .font(Font(WMFFont.for(.semiboldHeadline)))
                    .foregroundColor(isCorrect ? .green : .red)

                if let cardA = viewModel.cardViewModelA {
                    WMFOnThisDayCardView(viewModel: cardA)
                }
                if let cardB = viewModel.cardViewModelB {
                    WMFOnThisDayCardView(viewModel: cardB)
                }

                let isLast = viewModel.currentIndex == viewModel.totalQuestions - 1
                Button(isLast ? "See Results" : "Next") {
                    viewModel.advance()
                }
                .buttonStyle(GameButtonStyle(theme: theme))

                Spacer(minLength: 24)
            }
            .padding()
        }
    }

    // MARK: - Complete

    private func completeView() -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Game Complete!")
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(uiColor: theme.text))

            Text("\(viewModel.score) / \(viewModel.totalQuestions)")
                .font(Font(WMFFont.for(.boldTitle1)))
                .foregroundColor(Color(uiColor: theme.text))

            Text(scoreMessage)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }

    private var scoreMessage: String {
        switch viewModel.score {
        case viewModel.totalQuestions:
            return "Perfect score! 🎉"
        case (viewModel.totalQuestions / 2)...:
            return "Nice work! Come back tomorrow for a new game."
        default:
            return "Better luck tomorrow!"
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Text("Something went wrong")
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(uiColor: theme.text))
            Text(message)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)
            Button("Retry") {
                viewModel.load()
            }
            .buttonStyle(GameButtonStyle(theme: theme))
        }
        .padding()
    }

    // MARK: - Shared

    private func progressHeader() -> some View {
        HStack {
            Text("Question \(viewModel.currentIndex + 1) of \(viewModel.totalQuestions)")
                .font(Font(WMFFont.for(.caption1)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
            Spacer()
            Text("Score: \(viewModel.score)")
                .font(Font(WMFFont.for(.caption1)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
        }
    }
}

// MARK: - Button Style

private struct GameButtonStyle: ButtonStyle {
    let theme: WMFTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font(WMFFont.for(.semiboldSubheadline)))
            .foregroundColor(Color(uiColor: theme.paperBackground))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(uiColor: theme.link))
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - WMFWhichCameFirstEvent + onThisDayEvent

private extension WMFWhichCameFirstEvent {
    var onThisDayEvent: WMFOnThisDayEvent {
        WMFOnThisDayEvent(
            text: title,
            date: String(year),
            imageURL: thumbnailURL
        )
    }
}
