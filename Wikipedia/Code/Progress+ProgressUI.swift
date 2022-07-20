let WMFMinProgressDurationBeforeShowingProgressUI = 2.0

extension Progress {
    func wmf_shouldShowProgressUI() -> Bool {
        return isFinished == false && totalUnitCount > 0
    }
}
