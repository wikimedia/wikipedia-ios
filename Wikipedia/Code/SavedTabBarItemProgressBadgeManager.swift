
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
            // Observe any time this Progress object progresses.
            self?.progressFractionCompletedObservation = progressContainer.articleFetcherProgress?.observe(\Progress.fractionCompleted, options: [.new, .initial]) { [weak self] (progress, change) in
                self?.tabBarItem?.updateBadgeValue(for: progress)
            }
        }
    }
}

private extension Progress {
    func shouldShowBadge() -> Bool {
        return fractionCompleted > 0
    }
}

private extension UITabBarItem {
    func updateBadgeValue(for progress: Progress) {
        badgeValue = progress.shouldShowBadge() ? "\u{25cf}" : nil
    }
}
