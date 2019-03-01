import UIKit

public protocol SaveButtonsControllerDelegate: class {
    func didSaveArticle(_ saveButton: SaveButton?, didSave: Bool, article: WMFArticle, userInfo: Any?)
    func willUnsaveArticle(_ article: WMFArticle, userInfo: Any?)
    func showAddArticlesToReadingListViewController(for article: WMFArticle)
}

class SaveButtonsController: NSObject, SaveButtonDelegate {
    
    var visibleSaveButtons = [Int: Set<SaveButton>]()
    var visibleArticleKeys = [Int: String]()
    var visibleUserInfo = [Int: Any]()
    
    let dataStore: MWKDataStore
    let savedPagesFunnel = SavedPagesFunnel()
    var activeSender: SaveButton?
    var activeKey: String?
    
    required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(articleUpdated(notification:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func willDisplay(saveButton: SaveButton, for article: WMFArticle, with userInfo: Any? = nil) {
        guard let key = article.key else {
            return
        }
        let tag = key.hash
        saveButton.saveButtonState = article.savedDate == nil ? .longSave : .longSaved
        saveButton.tag = tag
        saveButton.addTarget(self, action: #selector(saveButtonPressed(sender:)), for: .touchUpInside)
        saveButton.saveButtonDelegate = self
        var saveButtons = visibleSaveButtons[tag] ?? []
        saveButtons.insert(saveButton)
        visibleSaveButtons[tag] = saveButtons
        visibleArticleKeys[tag] = key
        visibleUserInfo[tag] = userInfo
    }
    
    public func didEndDisplaying(saveButton: SaveButton, for article: WMFArticle) {
        guard let key = article.key else {
            return
        }
        let tag = key.hash
        saveButton.removeTarget(self, action: #selector(saveButtonPressed(sender:)), for: .touchUpInside)
        var saveButtons = visibleSaveButtons[tag] ?? []
        saveButtons.remove(saveButton)
        if saveButtons.isEmpty {
            visibleSaveButtons.removeValue(forKey: tag)
            visibleArticleKeys.removeValue(forKey: tag)
            visibleUserInfo.removeValue(forKey: tag)
        } else {
            visibleSaveButtons[tag] = saveButtons
        }
    }
    
    func saveButtonDidReceiveLongPress(_ saveButton: SaveButton) {
        _ = saveButtonDidReceiveAddToReadingListAction(saveButton)
    }
    
    func saveButtonDidReceiveAddToReadingListAction(_ saveButton: SaveButton) -> Bool {
        guard let key = visibleArticleKeys[saveButton.tag], let article = dataStore.fetchArticle(withKey: key) else {
            return false
        }

        activeKey = key
        activeSender = saveButton

        delegate?.showAddArticlesToReadingListViewController(for: article)
        return true
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
        notifyDelegateArticleSavedStateChanged()
    }
    
    public weak var delegate: SaveButtonsControllerDelegate?
    
    @objc func saveButtonPressed(sender: SaveButton) {
        guard let key = visibleArticleKeys[sender.tag] else {
            return
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        activeKey = key
        activeSender = sender
        
        if let articleToUnsave = dataStore.savedPageList.entry(forKey: key) {
            delegate?.willUnsaveArticle(articleToUnsave, userInfo: visibleUserInfo[sender.tag])
            return // don't unsave immediately, wait for a callback from WMFReadingListActionSheetControllerDelegate
        }
        
        updateSavedState()
    }
    
    func updateSavedState() {
        guard let key = activeKey else {
            return
        }

        let isSaved = dataStore.savedPageList.toggleSavedPage(forKey: key)
        
        if isSaved {
            savedPagesFunnel.logSaveNew(withArticleURL: updatedArticle?.url)
        } else {
            savedPagesFunnel.logDelete(withArticleURL: updatedArticle?.url)
        }
        notifyDelegateArticleSavedStateChanged()
    }
    
    private func notifyDelegateArticleSavedStateChanged() {
        guard let article = updatedArticle else {
            return
        }
        guard activeKey == article.key else {
            return
        }
        let tag = activeKey?.hash ?? 0
        let isSaved = article.savedDate != nil
        delegate?.didSaveArticle(activeSender, didSave: isSaved, article: article, userInfo: visibleUserInfo[tag])
        activeKey = nil
    }
}
