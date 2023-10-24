import UIKit

protocol WKEditorToolbarHighlightViewDelegate: AnyObject {
    func toolbarHighlightViewDidTapShowMore(toolbarView: WKEditorToolbarHighlightView)
    func toolbarHighlightViewDidTapFormatHeading(toolbarView: WKEditorToolbarHighlightView)
}

class WKEditorToolbarHighlightView: WKEditorToolbarView {
    
    // MARK: - Properties
    
    @IBOutlet private weak var stackView: UIStackView!
    
    @IBOutlet private weak var boldButton: WKEditorToolbarButton!
    @IBOutlet private weak var italicsButton: WKEditorToolbarButton!
    @IBOutlet private weak var formatHeadingButton: WKEditorToolbarButton!
    @IBOutlet private weak var citationButton: WKEditorToolbarButton!
    @IBOutlet private weak var linkButton: WKEditorToolbarButton!
    @IBOutlet private weak var templateButton: WKEditorToolbarButton!
    @IBOutlet private weak var clearMarkupButton: WKEditorToolbarButton!
    @IBOutlet private weak var showMoreButton: WKEditorToolbarNavigatorButton!
    
    weak var delegate: WKEditorToolbarHighlightViewDelegate?
    
    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        
        boldButton.setImage(WKIcon.bold, for: .normal)
        boldButton.addTarget(self, action: #selector(tappedBold), for: .touchUpInside)
        
        italicsButton.setImage(WKIcon.italics, for: .normal)
        italicsButton.addTarget(self, action: #selector(tappedItalics), for: .touchUpInside)
        
        formatHeadingButton.setImage(WKIcon.formatHeading, for: .normal)
        formatHeadingButton.addTarget(self, action: #selector(tappedFormatHeading), for: .touchUpInside)
        
        citationButton.setImage(WKIcon.citation, for: .normal)
        citationButton.addTarget(self, action: #selector(tappedCitation), for: .touchUpInside)
        
        linkButton.setImage(WKIcon.link, for: .normal)
        linkButton.addTarget(self, action: #selector(tappedLink), for: .touchUpInside)
        
        templateButton.setImage(WKIcon.template, for: .normal)
        templateButton.addTarget(self, action: #selector(tappedTemplate), for: .touchUpInside)
        
        clearMarkupButton.setImage(WKIcon.clear, for: .normal)
        clearMarkupButton.addTarget(self, action: #selector(tappedClearMarkup), for: .touchUpInside)
        
        showMoreButton.setImage(WKIcon.plusCircle, for: .normal)
        showMoreButton.addTarget(self, action: #selector(tappedShowMore), for: .touchUpInside)
    }
    
    // MARK: - Button Actions

    @objc private func tappedBold() {
    }

    @objc private func tappedItalics() {
    }

    @objc private func tappedFormatHeading() {
        delegate?.toolbarHighlightViewDidTapFormatHeading(toolbarView: self)
    }

    @objc private func tappedCitation() {
    }

    @objc private func tappedLink() {
    }

    @objc private func tappedTemplate() {
    }

    @objc private func tappedClearMarkup() {
    }

    @objc private func tappedShowMore() {
        delegate?.toolbarHighlightViewDidTapShowMore(toolbarView: self)
    }
}
