import Foundation

protocol ArticleSurveyTimerControllerDelegate: class {
    var isInValidSurveyCampaignAndArticleList: Bool { get }
    var shouldAttemptToShowArticleAsLivingDoc: Bool { get }
    var shouldShowArticleAsLivingDoc: Bool { get }
    var displayDelay: TimeInterval? { get }
    var livingDocSurveyLinkState: ArticleAsLivingDocSurveyLinkState { get }
}

 // Manages the timer used to display survey announcements on articles
final class ArticleSurveyTimerController {

    // MARK: - Public Properties

    var timerFireBlock: (() -> Void)?

    // MARK: - Private Properties

    private weak var delegate: ArticleSurveyTimerControllerDelegate?

    private var timer: Timer?
    private var timeIntervalRemainingWhenPaused: TimeInterval?
    private var shouldPauseOnBackground = false
    private var shouldResumeOnForeground: Bool { return shouldPauseOnBackground }

    // MARK: - Lifecycle

    init(delegate: ArticleSurveyTimerControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - Public

    func articleContentDidLoad() {
        startTimer()
    }

    func viewWillAppear(withState state: ArticleViewController.ViewState) {
        
        //do not kick off timer on ArticleViewController appearance if experiment is running.
        guard let delegate = delegate,
              !delegate.shouldAttemptToShowArticleAsLivingDoc else {
            return
        }
        
        kickoffTimer(withState: state)
    }
    
    func userDidScrollPastLivingDocArticleContentInsert(withState state: ArticleViewController.ViewState) {
        
        guard let delegate = delegate,
              !delegate.shouldShowArticleAsLivingDoc else {
            return
        }
        
        kickoffTimer(withState: state)
    }
    
    func extendTimer() {
        pauseTimer()
        let newTimeInterval = (timeIntervalRemainingWhenPaused ?? 0) + 5
        startTimer(withTimeInterval: newTimeInterval)
    }
    
    private func kickoffTimer(withState state: ArticleViewController.ViewState) {
        
        guard let delegate = delegate else {
            return
        }
        
        if state == .loaded, delegate.isInValidSurveyCampaignAndArticleList {
            shouldPauseOnBackground = true
            startTimer()
        }
    }

    func viewWillDisappear(withState state: ArticleViewController.ViewState) {
        // Do not listen for background/foreground notifications to pause and resume survey if this article is not on screen anymore
        if state == .loaded, delegate?.isInValidSurveyCampaignAndArticleList ?? false {
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
        guard let displayDelay = delegate?.displayDelay else {
            return
        }

        shouldPauseOnBackground = true
        let timeInterval = customTimeInterval ?? displayDelay

        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: { [weak self] timer in
            guard let self = self else {
                return
            }

            self.timerFireBlock?()
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

        timeIntervalRemainingWhenPaused = calculateRemainingTimerTimeInterval()
        stopTimer()
    }

    private func resumeTimer() {
        guard timer == nil, shouldResumeOnForeground else {
            return
        }

        startTimer(withTimeInterval: timeIntervalRemainingWhenPaused)
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
