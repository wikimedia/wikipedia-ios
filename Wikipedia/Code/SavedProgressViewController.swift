import UIKit

class SavedProgressViewController: UIViewController, Themeable {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    private var progressObjectWasSetObservation: NSKeyValueObservation?
    private var progressIsFinishedObservation: NSKeyValueObservation?
    
    fileprivate var theme: Theme = Theme.standard

    private var glassEffectView: UIVisualEffectView?

    private var innerContainerView: UIView? { view.subviews.first }

    private let horizontalPadding: CGFloat = 16
    private let bottomPadding: CGFloat = 8

    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = WMFLocalizedString("saved-pages-progress-syncing", value: "Article download in progress...", comment: "Text for article download progress bar label")
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        setupPillShape()
    }

    private func setupPillShape() {
        // Root view is transparent — the inner container is the visible pill
        view.backgroundColor = .clear

        guard let pill = innerContainerView else { return }

        // Remove the storyboard's edge-to-edge constraints so we can add horizontal insets
        for constraint in view.constraints where constraint.firstItem === pill || constraint.secondItem === pill {
            view.removeConstraint(constraint)
        }

        pill.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pill.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            pill.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            pill.topAnchor.constraint(equalTo: view.topAnchor),
            pill.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomPadding)
        ])

        pill.clipsToBounds = true
        pill.layer.cornerRadius = 24
        pill.layer.cornerCurve = .circular

        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .regular)
            glassEffect.tintColor = theme.colors.paperBackground.withAlphaComponent(0.85)
            let effectView = UIVisualEffectView(effect: glassEffect)
            effectView.frame = pill.bounds
            effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            pill.insertSubview(effectView, at: 0)
            glassEffectView = effectView
        }
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
        view.backgroundColor = .clear
        if #available(iOS 26.0, *) {
            glassEffectView?.effect = {
                let glassEffect = UIGlassEffect(style: .regular)
                glassEffect.tintColor = theme.colors.paperBackground.withAlphaComponent(0.85)
                return glassEffect
            }()
            innerContainerView?.backgroundColor = .clear
        } else {
            innerContainerView?.backgroundColor = theme.colors.paperBackground
        }
        label.textColor = theme.colors.primaryText
        progressView.progressTintColor = theme.colors.accent
    }
}
