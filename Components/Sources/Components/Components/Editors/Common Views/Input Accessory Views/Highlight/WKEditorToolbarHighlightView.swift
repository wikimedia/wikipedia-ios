import UIKit

protocol WKEditorToolbarHighlightViewDelegate: AnyObject {
    func toolbarHighlightViewDidTapBold(toolbarView: WKEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapItalics(toolbarView: WKEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapTemplate(toolbarView: WKEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapReference(toolbarView: WKEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapLink(toolbarView: WKEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapShowMore(toolbarView: WKEditorToolbarHighlightView)
}

class WKEditorToolbarHighlightView: WKEditorToolbarView {
    
    // MARK: - Properties
    
    @IBOutlet private weak var stackView: UIStackView!
    
    @IBOutlet private weak var boldButton: WKEditorToolbarButton!
    @IBOutlet private weak var italicsButton: WKEditorToolbarButton!
    @IBOutlet private weak var referenceButton: WKEditorToolbarButton!
    @IBOutlet private weak var linkButton: WKEditorToolbarButton!
    @IBOutlet private weak var templateButton: WKEditorToolbarButton!
    @IBOutlet private weak var showMoreButton: WKEditorToolbarNavigatorButton!
    
    weak var delegate: WKEditorToolbarHighlightViewDelegate?
    
    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        
        boldButton.setImage(WKSFSymbolIcon.for(symbol: .bold))
        boldButton.addTarget(self, action: #selector(tappedBold), for: .touchUpInside)
        boldButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.toolbarBoldButtonAccessibility

        italicsButton.setImage(WKSFSymbolIcon.for(symbol: .italic))
        italicsButton.addTarget(self, action: #selector(tappedItalics), for: .touchUpInside)
        italicsButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.toolbarItalicsButtonAccessibility

        referenceButton.setImage(WKSFSymbolIcon.for(symbol: .quoteOpening))
        referenceButton.addTarget(self, action: #selector(tappedReference), for: .touchUpInside)
        referenceButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.toolbarReferenceButtonAccessibility

        linkButton.setImage(WKSFSymbolIcon.for(symbol: .link))
        linkButton.addTarget(self, action: #selector(tappedLink), for: .touchUpInside)
        linkButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.toolbarLinkButtonAccessibility

        templateButton.setImage(WKSFSymbolIcon.for(symbol: .curlybraces))
        templateButton.addTarget(self, action: #selector(tappedTemplate), for: .touchUpInside)
        templateButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.toolbarTemplateButtonAccessibility
        showMoreButton.setImage(WKSFSymbolIcon.for(symbol: .plusCircleFill), for: .normal)
        showMoreButton.addTarget(self, action: #selector(tappedShowMore), for: .touchUpInside)
        showMoreButton.accessibilityIdentifier = WKSourceEditorAccessibilityIdentifiers.current?.showMoreButton
        showMoreButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.toolbarOpenTextFormatMenuButtonAccessibility
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonSelectionState(_:)), name: Notification.WKSourceEditorSelectionState, object: nil)
        
        accessibilityElements = [boldButton as Any, italicsButton as Any, referenceButton as Any, linkButton as Any, templateButton as Any, showMoreButton as Any]
    }
    
    // MARK: - Notifications
    
    @objc private func updateButtonSelectionState(_ notification: NSNotification) {
        guard let selectionState = notification.userInfo?[Notification.WKSourceEditorSelectionStateKey] as? WKSourceEditorSelectionState else {
            return
        }
        
        boldButton.isSelected = selectionState.isBold
        italicsButton.isSelected = selectionState.isItalics
        templateButton.isSelected = selectionState.isHorizontalTemplate
        referenceButton.isSelected = selectionState.isHorizontalReference
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

    @objc private func tappedReference() {
        delegate?.toolbarHighlightViewDidTapReference(toolbarView: self, isSelected: referenceButton.isSelected)
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
