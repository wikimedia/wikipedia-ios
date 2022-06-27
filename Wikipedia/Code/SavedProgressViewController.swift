import UIKit

class SavedProgressViewController: UIViewController, Themeable {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    private var progressObjectWasSetObservation: NSKeyValueObservation?
    private var progressIsFinishedObservation: NSKeyValueObservation?
    
    fileprivate var theme: Theme = Theme.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = WMFLocalizedString("saved-pages-progress-syncing", value: "Article download in progress...", comment: "Text for article download progress bar label")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Reminder: because NSProgress can not be re-used, we have to re-start observation any time this view appears so we're looking at the current NSProgress.
        beginProgressObservations()
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        endProgressObservations()
    }
    
    private func beginProgressObservations() {
        // Observe any time a new Progress object is set. (NSProgress are not re-usable so you need to reset it if you're tracking a new progression)
        progressObjectWasSetObservation = ProgressContainer.shared.observe(\ProgressContainer.articleFetcherProgress, options: [.new, .initial]) { [weak self] (progressContainer, change) in
            self?.progressView.observedProgress = progressContainer.articleFetcherProgress
            self?.progressIsFinishedObservation?.invalidate()
            
            var exceededMinSyncInProgressDuration = false
            
            // Observe any time this Progress object finishes.
            self?.progressIsFinishedObservation = progressContainer.articleFetcherProgress?.observe(\Progress.isFinished, options: [.new, .initial]) { [weak self] (progress, change) in
                
                guard progress.wmf_shouldShowProgressUI() else {
                    exceededMinSyncInProgressDuration = false
                    self?.animate(isHidden: true)
                    return
                }
                exceededMinSyncInProgressDuration = true
                
                dispatchOnMainQueueAfterDelayInSeconds(WMFMinProgressDurationBeforeShowingProgressUI) { [weak self] in
                    // If `exceededMinSyncInProgressDuration` is still true here we've exceeded the min so it's ok to show progress view.
                    guard exceededMinSyncInProgressDuration else {
                        return
                    }
                    self?.animate(isHidden: false)
                }
            }
        }
    }

    private func endProgressObservations() {
        progressIsFinishedObservation?.invalidate()
        progressIsFinishedObservation = nil
        progressObjectWasSetObservation?.invalidate()
        progressObjectWasSetObservation = nil
        progressView.observedProgress = nil
    }

    private func animate(isHidden: Bool) {
        UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.view.isHidden = isHidden
        })
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        view.backgroundColor = theme.colors.hintBackground
        label.textColor = theme.colors.secondaryText
        progressView.progressTintColor = theme.colors.accent
    }
}
