import WMFComponents
import WMF
import CocoaLumberjackSwift
import WMFData

// MARK: - ArticleViewController + LeadImage
extension ArticleViewController {
    @objc func userDidTapLeadImage() {
        showLeadImage()
    }
    
    func loadLeadImage(with leadImageURL: URL) {
        leadImageHeightConstraint.constant = leadImageHeight
        leadImageView.wmf_setImage(with: leadImageURL, detectFaces: true, onGPU: true, failure: { (error) in
            DDLogWarn("Error loading lead image: \(error)")
        }) {
            self.updateLeadImageMargins()
            self.updateArticleMargins()
            
            /// see implementation in `extension ArticleViewController: UIContextMenuInteractionDelegate`
            let interaction = UIContextMenuInteraction(delegate: self)
            self.leadImageView.addInteraction(interaction)
        }
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        updateLeadImageMargins()
    }
    
    func updateLeadImageMargins() {
        let doesArticleUseLargeMargin = (tableOfContentsController.viewController.displayMode == .inline && !tableOfContentsController.viewController.isVisible)
        var marginWidth: CGFloat = 0
        if doesArticleUseLargeMargin {
            marginWidth = articleHorizontalMargin
        }
        leadImageLeadingMarginConstraint.constant = marginWidth
        leadImageTrailingMarginConstraint.constant = marginWidth
    }
}
