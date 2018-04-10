
@objcMembers class SavedTabBarItemProgressBadgeManager: NSObject {
    private var progressObjectWasSetObservation: NSKeyValueObservation?
    private var progressFractionCompletedObservation: NSKeyValueObservation?
    
    weak var tabBarItem: UITabBarItem? = nil

    @objc(initWithTabBarItem:)
    public required init(with tabBarItem: UITabBarItem) {
        self.tabBarItem = tabBarItem
        super.init()
        beginProgressObservations()
    }
    
    private func beginProgressObservations(){
        // Observe any time a new Progress object is set. (NSProgress are not re-usable so you need to reset it if you're tracking a new progression)
        progressObjectWasSetObservation = ProgressContainer.shared.observe(\ProgressContainer.articleFetcherProgress, options: [.new, .initial]) { [weak self] (progressContainer, change) in
            self?.progressFractionCompletedObservation?.invalidate()
            
            var exceededMinSyncInProgressDuration = false
            
            // Observe any time this Progress object progresses.
            self?.progressFractionCompletedObservation = progressContainer.articleFetcherProgress?.observe(\Progress.fractionCompleted, options: [.new, .initial]) { [weak self] (progress, change) in
                
                guard progress.wmf_shouldShowProgressUI() else {
                    exceededMinSyncInProgressDuration = false
                    self?.tabBarItem?.showBadge(false)
                    return
                }
                exceededMinSyncInProgressDuration = true

                dispatchOnMainQueueAfterDelayInSeconds(WMFMinProgressDurationBeforeShowingProgressUI) { [weak self] in
                    // If `exceededMinSyncInProgressDuration` is still true here we've exceeded the min so it's ok to show badge.
                    guard exceededMinSyncInProgressDuration else {
                        return
                    }
                    self?.tabBarItem?.showBadge(true)
                }
            }
        }
    }
}

private extension UITabBarItem {
    func showBadge(_ shouldShow: Bool) {
        badgeValue = shouldShow ? "\u{2605}" : nil
    }
}
