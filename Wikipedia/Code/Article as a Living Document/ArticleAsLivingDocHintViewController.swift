import Foundation

@objc(WMFArticleAsLivingDocHintViewController)
class ArticleAsLivingDocHintViewController: HintViewController {
    
    override var extendsUnderSafeArea: Bool {
        return true
    }
    
    override func configureSubviews() {
        viewType = .warning
        warningLabel.text = CommonStrings.articleAsLivingDocErrorTitle
        warningSubtitleLabel.text = CommonStrings.articleAsLivingDocErrorSubtitle
    }
}
