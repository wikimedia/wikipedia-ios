import UIKit

@objc public protocol WMFSaveButtonsControllerDelegate: NSObjectProtocol {
    func didSaveArticle(_ didSave: Bool, article: WMFArticle)
    func willUnsaveArticle(_ article: WMFArticle)
}

@objc(WMFSaveButtonsController) class SaveButtonsController: NSObject {
    
    var visibleSaveButtons = [Int: Set<SaveButton>]()
    var visibleArticleKeys = [Int: String]()
    let dataStore: MWKDataStore
    let savedPagesFunnel = SavedPagesFunnel()
    var activeSender: SaveButton?
    var activeKey: String?
    
    @objc required init(dataStore: MWKDataStore) {
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
        var saveButtons = visibleSaveButtons[tag] ?? []
        saveButtons.insert(saveButton)
        visibleSaveButtons[tag] = saveButtons
        visibleArticleKeys[tag] = key
    }
    
    @objc(didEndDisplayingSaveButton:forArticle:)
    public func didEndDisplaying(saveButton: SaveButton, for article: WMFArticle) {
        guard let key = article.key else {
            return
        }
        let tag = key.hash
        saveButton.removeTarget(self, action: #selector(saveButtonPressed(sender:)), for: .touchUpInside)
        var saveButtons = visibleSaveButtons[tag] ?? []
        saveButtons.remove(saveButton)
        if saveButtons.count == 0 {
            visibleSaveButtons.removeValue(forKey: tag)
            visibleArticleKeys.removeValue(forKey: tag)
        } else {
            visibleSaveButtons[tag] = saveButtons
        }
    }
    
    fileprivate var updatedArticle: WMFArticle?
    
    @objc func articleUpdated(notification: Notification) {
        guard let article = notification.object as? WMFArticle, let key = article.key, let saveButtons = visibleSaveButtons[key.hash] else {
            return
        }
        for saveButton in saveButtons {
            saveButton.saveButtonState = article.savedDate == nil ? .longSave : .longSaved
        }
        updatedArticle = article
    }
    
    @objc public weak var delegate: WMFSaveButtonsControllerDelegate?
    
    @objc func saveButtonPressed(sender: SaveButton) {
        guard let key = visibleArticleKeys[sender.tag] else {
            return
        }
        
        self.activeKey = key
        self.activeSender = sender
        
        if let articleToUnsave = dataStore.savedPageList.entry(forKey: key) {
            delegate?.willUnsaveArticle(articleToUnsave)
            return // don't unsave immediately, wait for a callback from WMFReadingListActionSheetControllerDelegate
        }
        
        updateSavedState()
    }
    
    @objc func updateSavedState() {
        guard let key = activeKey, let sender = activeSender else {
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
        if let article = updatedArticle {
            delegate?.didSaveArticle(isSaved, article: article)
        }
    }
}
