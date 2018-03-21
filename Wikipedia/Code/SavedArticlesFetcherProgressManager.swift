/*
 This class acts as a bridge between the SavedArticlesFetcher (which retrieves article html and images) and VC's which want to display save article fetching progress. It does so while being minimally invasive to SavedArticlesFetcher, observing only the SavedArticlesFetcher's 'fetchesInProcessCount'. Interested VC's can access the SavedArticlesFetcherProgressManager.shared.progress - but be aware that this "progress" object is not re-used, so you'll need to observe it to know when it gets re-set, and you'll then have to observe any properties you are interested in of the re-set progress. Reason:
 
 "NSProgress objects cannot be reused. Once they’re done, they’re done. Once they’re cancelled, they’re cancelled. If you need to reuse an NSProgress, instead make a new instance and provide a mechanism so the client of your progress knows that the object has been replaced, like a notification." ( Source: https://developer.apple.com/videos/play/wwdc2015/232/ by way of https://stinkykitten.com/index.php/2017/08/13/nsprogress/ )
*/

@objcMembers class SavedArticlesFetcherProgressManager: NSObject, ProgressReporting {

    static let shared = SavedArticlesFetcherProgressManager()

    dynamic private(set) var progress = SavedArticlesFetcherProgressManager.newProgress()

    private var fetchesInProcessCountObservation: NSKeyValueObservation?
    
    private static func newProgress() -> Progress {
        return Progress.discreteProgress(totalUnitCount: -1)
    }

    private func resetProgress() {
        // Reminder - see the note above for why this gets reset after finish.
        progress = SavedArticlesFetcherProgressManager.newProgress()
    }
    
    var fetcher: SavedArticlesFetcher? {
        didSet {
            fetchesInProcessCountObservation?.invalidate()
            if let fetcher = fetcher {
                fetchesInProcessCountObservation = fetcher.observe(\SavedArticlesFetcher.fetchesInProcessCount, options: [.new, .old]) { [weak self] (fetcher, change) in
                    if
                        let newValue = change.newValue?.int64Value,
                        let oldValue = change.oldValue?.int64Value,
                        let progress = self?.progress
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
                            self?.resetProgress()
                        }
                    }
                }
            } else {
                fetchesInProcessCountObservation?.invalidate()
            }
        }
    }
}

extension Progress {
    func wmf_shouldShowProgressView() ->  Bool {
        return isFinished == false && totalUnitCount > 0
    }
}
