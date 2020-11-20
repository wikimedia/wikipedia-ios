import Foundation

protocol ArticleSurveyTimerControllerDelegate: class {
    var isInValidSurveyCampaignAndArticleList: Bool { get }
    var shouldAttemptToShowArticleAsLivingDoc: Bool { get }
    var shouldShowArticleAsLivingDoc: Bool { get }
    var userHasSeenSurveyPrompt: Bool { get }
    var displayDelay: TimeInterval? { get }
    var livingDocSurveyLinkState: ArticleAsLivingDocSurveyLinkState { get }
}

 // Manages the timer used to display survey announcements on articles
final class ArticleSurveyTimerController {
    
    private var isInExperimentAndAllowedArticleList: Bool {
        
        guard let delegate = delegate else {
            return false
        }
        
        return delegate.shouldAttemptToShowArticleAsLivingDoc && delegate.isInValidSurveyCampaignAndArticleList
    }
    
    private var isInControlAndAllowedArticleList: Bool {
        guard let delegate = delegate else {
            return false
        }
        
        return !delegate.shouldAttemptToShowArticleAsLivingDoc && delegate.isInValidSurveyCampaignAndArticleList
    }

    // MARK: - Public Properties

    var timerFireBlock: (() -> Void)?

    // MARK: - Private Properties

    private weak var delegate: ArticleSurveyTimerControllerDelegate?

    private var timer: Timer?
    private var timeIntervalRemainingWhenPaused: TimeInterval?
    private var shouldPauseOnBackground = false
    private var shouldResumeOnForeground: Bool { return shouldPauseOnBackground }
    private var didScrollPastLivingDocContentInsertAndStartedTimer: Bool = false

    // MARK: - Lifecycle

    init(delegate: ArticleSurveyTimerControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - Public

    func articleContentDidLoad() {
        
        guard let delegate = delegate,
              !delegate.userHasSeenSurveyPrompt,
              isInControlAndAllowedArticleList else {
            return
        }
        
        startTimer()
    }
    
    func livingDocViewWillAppear(withState state: ArticleViewController.ViewState) {
        
        guard let delegate = delegate,
              state == .loaded,
              !delegate.userHasSeenSurveyPrompt,
              timer == nil,
              isInExperimentAndAllowedArticleList else {
            return
        }
        
        startTimer()
    }
    
    func livingDocViewWillPush(withState state: ArticleViewController.ViewState) {
        viewWillDisappear(withState: state)
    }

    func viewWillAppear(withState state: ArticleViewController.ViewState) {
        
        guard let delegate = delegate,
              state == .loaded,
              !delegate.userHasSeenSurveyPrompt,
              ((isInExperimentAndAllowedArticleList && didScrollPastLivingDocContentInsertAndStartedTimer) || isInControlAndAllowedArticleList) else {
            return
        }
        
        startTimer()
    }
    
    func userDidScrollPastLivingDocArticleContentInsert(withState state: ArticleViewController.ViewState) {
        
        guard let delegate = delegate,
              state == .loaded,
              !delegate.userHasSeenSurveyPrompt,
              isInExperimentAndAllowedArticleList else {
            return
        }
        
        didScrollPastLivingDocContentInsertAndStartedTimer = true
        
        startTimer()
    }
    
    func extendTimer() {
        
        guard let delegate = delegate,
            !delegate.userHasSeenSurveyPrompt,
            isInExperimentAndAllowedArticleList else {
            return
        }
                
        pauseTimer()
        let newTimeInterval = (timeIntervalRemainingWhenPaused ?? 0) + 5
        startTimer(withTimeInterval: newTimeInterval)
        
    }

    func viewWillDisappear(withState state: ArticleViewController.ViewState) {
        // Do not listen for background/foreground notifications to pause and resume survey if this article is not on screen anymore
        
        guard let delegate = delegate,
              state == .loaded,
              !delegate.userHasSeenSurveyPrompt,
              (isInControlAndAllowedArticleList || isInExperimentAndAllowedArticleList) else {
            return
        }
        
        shouldPauseOnBackground = false
        stopTimer()
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
