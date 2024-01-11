import UIKit

protocol WKEditorToolbarHighlightViewDelegate: AnyObject {
    func toolbarHighlightViewDidTapBold(toolbarView: WKEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapItalics(toolbarView: WKEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapTemplate(toolbarView: WKEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapLink(toolbarView: WKEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapShowMore(toolbarView: WKEditorToolbarHighlightView)
}

class WKEditorToolbarHighlightView: WKEditorToolbarView {
    
    // MARK: - Properties
    
    @IBOutlet private weak var stackView: UIStackView!
    
    @IBOutlet private weak var boldButton: WKEditorToolbarButton!
    @IBOutlet private weak var italicsButton: WKEditorToolbarButton!
    @IBOutlet private weak var citationButton: WKEditorToolbarButton!
    @IBOutlet private weak var linkButton: WKEditorToolbarButton!
    @IBOutlet private weak var templateButton: WKEditorToolbarButton!
    @IBOutlet private weak var showMoreButton: WKEditorToolbarNavigatorButton!
    
    weak var delegate: WKEditorToolbarHighlightViewDelegate?
    
    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        accessibilityElements = buttons + [showMoreButton as Any]
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        
        boldButton.setImage(WKSFSymbolIcon.for(symbol: .bold), for: .normal)
        boldButton.addTarget(self, action: #selector(tappedBold), for: .touchUpInside)
        boldButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonBold

        italicsButton.setImage(WKSFSymbolIcon.for(symbol: .italic), for: .normal)
        italicsButton.addTarget(self, action: #selector(tappedItalics), for: .touchUpInside)
        italicsButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonItalics

        citationButton.setImage(WKSFSymbolIcon.for(symbol: .quoteOpening), for: .normal)
        citationButton.addTarget(self, action: #selector(tappedCitation), for: .touchUpInside)
        citationButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonCitation

        linkButton.setImage(WKSFSymbolIcon.for(symbol: .link), for: .normal)
        linkButton.addTarget(self, action: #selector(tappedLink), for: .touchUpInside)
        linkButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonLink

        templateButton.setImage(WKSFSymbolIcon.for(symbol: .curlybraces), for: .normal)
        templateButton.addTarget(self, action: #selector(tappedTemplate), for: .touchUpInside)
        templateButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonTemplate
        showMoreButton.setImage(WKSFSymbolIcon.for(symbol: .plusCircleFill), for: .normal)
        showMoreButton.addTarget(self, action: #selector(tappedShowMore), for: .touchUpInside)
        showMoreButton.accessibilityIdentifier = WKSourceEditorAccessibilityIdentifiers.current?.showMoreButton
        showMoreButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonShowMore
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonSelectionState(_:)), name: Notification.WKSourceEditorSelectionState, object: nil)
    }
    
    // MARK: - Notifications
    
    @objc private func updateButtonSelectionState(_ notification: NSNotification) {
        guard let selectionState = notification.userInfo?[Notification.WKSourceEditorSelectionStateKey] as? WKSourceEditorSelectionState else {
            return
        }
        
        boldButton.isSelected = selectionState.isBold
        italicsButton.isSelected = selectionState.isItalics
        templateButton.isSelected = selectionState.isHorizontalTemplate
        linkButton.isSelected = selectionState.isSimpleLink
    }
    
    // MARK: - Button Actions

    @objc private func tappedBold() {
        delegate?.toolbarHighlightViewDidTapBold(toolbarView: self, isSelected: boldButton.isSelected)
    }

    @objc private func tappedItalics() {
        delegate?.toolbarHighlightViewDidTapItalics(toolbarView: self, isSelected: italicsButton.isSelected)
    }

    @objc private func tappedFormatHeading() {
    }

    @objc private func tappedCitation() {
    }

    @objc private func tappedLink() {
        delegate?.toolbarHighlightViewDidTapLink(toolbarView: self, isSelected: linkButton.isSelected)
    }

    @objc private func tappedTemplate() {
        delegate?.toolbarHighlightViewDidTapTemplate(toolbarView: self, isSelected: templateButton.isSelected)
    }

    @objc private func tappedClearMarkup() {
    }

    @objc private func tappedShowMore() {
        delegate?.toolbarHighlightViewDidTapShowMore(toolbarView: self)
    }
}
