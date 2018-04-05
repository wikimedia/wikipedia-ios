/*
 This class is responsible for updating SavedArticlesFetcher's 'progress' object - both setting it and updating its unit counts when appropriate. It does so while being minimally invasive to SavedArticlesFetcher, observing only the SavedArticlesFetcher's 'fetchesInProcessCount'. Remember that SavedArticlesFetcher's 'progress' object is not re-used (per Apple's NSProgress docs), so you'll need to observe it to know when it gets re-set, and you'll then have to observe any properties you are interested in of the re-set progress.
*/
@objcMembers class SavedArticlesFetcherProgressManager: NSObject {
    
    private var fetchesInProcessCountObservation: NSKeyValueObservation?
    weak var delegate: SavedArticlesFetcher? = nil
    
    @objc(initWithDelegate:)
    public required init(with delegate: SavedArticlesFetcher) {
        self.delegate = delegate
        super.init()
        setup()
    }

    private func resetProgress() {
        self.delegate?.progress = Progress.discreteProgress(totalUnitCount: -1)
    }

    private func setup(){
        self.resetProgress()
        fetchesInProcessCountObservation = self.delegate?.observe(\SavedArticlesFetcher.fetchesInProcessCount, options: [.new, .old]) { [weak self] (fetcher, change) in
            if
                let newValue = change.newValue?.int64Value,
                let oldValue = change.oldValue?.int64Value,
                let progress = self?.delegate?.progress
            {
                // Advance totalUnitCount if new units were added
                let deltaValue = newValue - oldValue
                let wereNewUnitsAdded = deltaValue > 0
                if wereNewUnitsAdded {
                    progress.totalUnitCount = progress.totalUnitCount + deltaValue
                }
                
                // Update completedUnitCount
                let unitsRemaining = progress.totalUnitCount - newValue
                progress.completedUnitCount = unitsRemaining
                
                // Reset on finish
                let wereAllUnitsCompleted = newValue == 0 && oldValue > 0
                if wereAllUnitsCompleted {
                    // "NSProgress objects cannot be reused. Once they’re done, they’re done. Once they’re cancelled, they’re cancelled. If you need to reuse an NSProgress, instead make a new instance and provide a mechanism so the client of your progress knows that the object has been replaced, like a notification." ( Source: https://developer.apple.com/videos/play/wwdc2015/232/ by way of https://stinkykitten.com/index.php/2017/08/13/nsprogress/ )
                    self?.resetProgress()
                }
            }
        }
    }
}
