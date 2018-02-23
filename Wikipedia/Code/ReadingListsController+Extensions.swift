extension ReadingListsController {
    public func handle(_ error: Error) {
        if let readingListsError = error as? ReadingListError {
            WMFAlertManager.sharedInstance.showAlert(readingListsError.localizedDescription, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        } else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(
                CommonStrings.unknownError, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
        }
    }
}
