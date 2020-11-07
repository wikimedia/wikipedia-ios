import Foundation

/// Manages the timer used to display survey announcements on articles
final class ArticleSurveyTimerController {

    // MARK: - Public Properties

    var timerFireBlock: ((SurveyAnnouncementsController.SurveyAnnouncementResult) -> Void)?

    // MARK: - Private Properties

    private let articleURL: URL
    private let surveyController: SurveyAnnouncementsController

    private var timer: Timer?
    private var timeIntervalRemainingWhenBackgrounded: TimeInterval?
    private var shouldPauseOnBackground = false
    private var shouldResumeOnForeground: Bool { return shouldPauseOnBackground }

    // MARK: - Computed Properties

    private var surveyAnnouncementResult: SurveyAnnouncementsController.SurveyAnnouncementResult? {
        return surveyController.activeSurveyAnnouncementResultForArticleURL(articleURL)
    }

    // MARK: - Lifecycle

    init(articleURL: URL, surveyController: SurveyAnnouncementsController) {
        self.articleURL = articleURL
        self.surveyController = surveyController
    }

    // MARK: - Public

    func articleContentDidLoad() {
        startTimer()
    }

    func viewWillAppear(withState state: ArticleViewController.ViewState) {
        if state == .loaded, surveyAnnouncementResult != nil {
            shouldPauseOnBackground = true
            startTimer()
        }
    }

    func viewWillDisappear(withState state: ArticleViewController.ViewState) {
        // Do not listen for background/foreground notifications to pause and resume survey if this article is not on screen anymore
        if state == .loaded, surveyAnnouncementResult != nil {
            shouldPauseOnBackground = false
            stopTimer()
        }
    }

    func willResignActive(withState state: ArticleViewController.ViewState) {
        if state == .loaded, shouldPauseOnBackground {
            pauseTimer()
        }
    }

    func didBecomeActive(withState state: ArticleViewController.ViewState) {
        if state == .loaded, shouldResumeOnForeground {
            resumeTimer()
        }
    }

    // MARK: - Timer State Management

    private func startTimer(withTimeInterval customTimeInterval: TimeInterval? = nil) {
        guard let surveyAnnouncementResult = surveyAnnouncementResult else {
            return
        }

        shouldPauseOnBackground = true
        let timeInterval = customTimeInterval ?? surveyAnnouncementResult.displayDelay

        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: { [weak self] timer in
            guard let self = self else {
                return
            }

            self.timerFireBlock?(surveyAnnouncementResult)
            self.stopTimer()
            self.shouldPauseOnBackground = false
        })
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func pauseTimer() {
        guard timer != nil, shouldPauseOnBackground else {
            return
        }

        timeIntervalRemainingWhenBackgrounded = calculateRemainingTimerTimeInterval()
        stopTimer()
    }

    private func resumeTimer() {
        guard timer == nil, shouldResumeOnForeground else {
            return
        }

        startTimer(withTimeInterval: timeIntervalRemainingWhenBackgrounded)
    }

    /// Calculate remaining TimeInterval (if any) until survey timer fire date
    private func calculateRemainingTimerTimeInterval() -> TimeInterval? {
        guard let timer = timer else {
            return nil
        }

        let remainingTime = timer.fireDate.timeIntervalSince(Date())
        return remainingTime < 0 ? nil : remainingTime
    }

}
