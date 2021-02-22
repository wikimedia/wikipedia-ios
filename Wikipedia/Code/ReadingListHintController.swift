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

    override func toggle(presenter: HintPresentingViewController, context: HintController.Context?, theme: Theme) {
        super.toggle(presenter: presenter, context: context, theme: theme)
        guard let article = context?[ReadingListHintController.ContextArticleKey] as? WMFArticle else {
            return
        }
        let didSave = article.isSaved
        let didSaveOtherArticle = didSave && !isHintHidden && article != readingListHintViewController.article
        let didUnsaveOtherArticle = !didSave && !isHintHidden && article != readingListHintViewController.article

        guard !didUnsaveOtherArticle else {
            return
        }

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

extension ReadingListHintController {
    @objc public static let ContextArticleKey = "ContextArticleKey"
}
