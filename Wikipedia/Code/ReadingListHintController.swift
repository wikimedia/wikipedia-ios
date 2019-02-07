import UIKit

@objc(WMFReadingListHintController)
class ReadingListHintController: HintController {

    private let readingListHintViewController = ReadingListHintViewController()
    private let dataStore: MWKDataStore
    private var containerView = UIView()
        
    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        readingListHintViewController.dataStore = dataStore
        super.init(hintViewController: readingListHintViewController)
    }

    @objc func toggleHintForArticle(_ article: WMFArticle, theme: Theme) {
        let didSave = article.savedDate != nil

        let didSaveOtherArticle = didSave && !isHintHidden && article != readingListHintViewController.article
        let didUnsaveOtherArticle = !didSave && !isHintHidden && article != readingListHintViewController.article

        guard !didUnsaveOtherArticle else {
            return
        }

        apply(theme: theme)

        guard !didSaveOtherArticle else {
            resetHint()
            dismissHint()
            readingListHintViewController.article = article
            return
        }

        readingListHintViewController.article = article
        setHintHidden(!didSave)
    }
}
