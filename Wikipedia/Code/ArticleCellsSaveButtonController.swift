import UIKit

@objc(WMFArticleCellsSaveButtonController) class ArticleCellsSaveButtonController: NSObject {
    
    var visibleSaveButtons = [Int: SaveButton]()
    var visibleArticleKeys = [Int: String]()
    let dataStore: MWKDataStore
    
    required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(articleUpdated(notification:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc(willDisplayCell:forArticle:) func willDisplay(cell: ArticleCollectionViewCell, for article: WMFArticle) {
        guard let saveButton = cell.saveButton, let key = article.key else {
            return
        }
        let tag = key.hash
        saveButton.saveButtonState = article.savedDate == nil ? .longSave : .longSaved
        saveButton.tag = tag
        saveButton.addTarget(self, action: #selector(saveButtonPressed(sender:)), for: .touchUpInside)
        visibleSaveButtons[tag] = saveButton
        visibleArticleKeys[tag] = key
    }
    
    @objc(didEndDisplayingCell:forArticle:) func didEndDisplaying(cell: ArticleCollectionViewCell, for article: WMFArticle) {
        guard let saveButton = cell.saveButton, let key = article.key else {
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
    
    func saveButtonPressed(sender: UIButton) {
        guard let key = visibleArticleKeys[sender.tag] else {
            return
        }
        dataStore.savedPageList.toggleSavedPage(forKey: key)
    }
}
