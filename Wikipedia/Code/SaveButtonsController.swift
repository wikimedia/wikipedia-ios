import UIKit

@objc(WMFSaveButtonsController) class SaveButtonsController: NSObject {
    
    var visibleSaveButtons = [Int: SaveButton]()
    var visibleArticleKeys = [Int: String]()
    let dataStore: MWKDataStore
    let savedPagesFunnel = SavedPagesFunnel()
    
    required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(articleUpdated(notification:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc(willDisplaySaveButton:forArticle:)
    public func willDisplay(saveButton: SaveButton, for article: WMFArticle) {
        guard let key = article.key else {
            return
        }
        let tag = key.hash
        saveButton.saveButtonState = article.savedDate == nil ? .longSave : .longSaved
        saveButton.tag = tag
        saveButton.addTarget(self, action: #selector(saveButtonPressed(sender:)), for: .touchUpInside)
        visibleSaveButtons[tag] = saveButton
        visibleArticleKeys[tag] = key
    }
    
    @objc(didEndDisplayingSaveButton:forArticle:)
    public func didEndDisplaying(saveButton: SaveButton, for article: WMFArticle) {
        guard let key = article.key else {
            return
        }
        let tag = key.hash
        saveButton.removeTarget(self, action: #selector(saveButtonPressed(sender:)), for: .touchUpInside)
        visibleSaveButtons.removeValue(forKey: tag)
        visibleArticleKeys.removeValue(forKey: tag)
    }
    
    func articleUpdated(notification: Notification) {
        guard let article = notification.object as? WMFArticle, let key = article.key, let saveButton = visibleSaveButtons[key.hash] else {
            return
        }
        saveButton.saveButtonState = article.savedDate == nil ? .longSave : .longSaved
    }
    
    func saveButtonPressed(sender: SaveButton) {
        guard let key = visibleArticleKeys[sender.tag] else {
            return
        }
        let isSaved = dataStore.savedPageList.toggleSavedPage(forKey: key)
        
        if isSaved {
            PiwikTracker.sharedInstance()?.wmf_logActionSave(inContext: sender, contentType: sender)
            savedPagesFunnel.logSaveNew()
        } else {
            PiwikTracker.sharedInstance()?.wmf_logActionUnsave(inContext: sender, contentType: sender)
            savedPagesFunnel.logDelete()
        }
    }
}
