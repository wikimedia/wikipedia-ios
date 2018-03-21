import UIKit

class SavedProgressViewController: UIViewController, Themeable {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    private var progressObjectWasSetObservation: NSKeyValueObservation?
    private var progressIsFinishedObservation: NSKeyValueObservation?
    
    fileprivate var theme: Theme = Theme.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = WMFLocalizedString("saved-pages-progress-syncing", value: "Article syncing in progress...", comment: "Text for article syncing progress bar label")
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
    
    private func beginProgressObservations(){
        // Observe any time a new Progress object is set. (NSProgress are not re-usable so you need to reset it if you're tracking a new progression)
        progressObjectWasSetObservation = SavedArticlesFetcherProgressManager.shared.observe(\SavedArticlesFetcherProgressManager.progress, options: [.new, .initial]) { [weak self] (fetchProgressManager, change) in
            self?.progressView.observedProgress = fetchProgressManager.progress
            self?.progressIsFinishedObservation?.invalidate()
            // Observe any time this Progress object finishes.
            self?.progressIsFinishedObservation = fetchProgressManager.progress.observe(\Progress.isFinished, options: [.new, .initial]) { [weak self] (progress, change) in
                self?.view.isHidden = !progress.wmf_shouldShowProgressView()
            }
        }
    }

    private func endProgressObservations(){
        progressIsFinishedObservation?.invalidate()
        progressIsFinishedObservation = nil
        progressObjectWasSetObservation?.invalidate()
        progressObjectWasSetObservation = nil
        progressView.observedProgress = nil
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        view.backgroundColor = theme.colors.hintBackground
        label.textColor = theme.colors.secondaryText
        progressView.progressTintColor = theme.colors.accent
    }
}
