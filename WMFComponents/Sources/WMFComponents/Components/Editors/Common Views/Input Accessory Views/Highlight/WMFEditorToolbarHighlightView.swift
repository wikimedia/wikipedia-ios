import UIKit

protocol WMFEditorToolbarHighlightViewDelegate: AnyObject {
    func toolbarHighlightViewDidTapBold(toolbarView: WMFEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapItalics(toolbarView: WMFEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapTemplate(toolbarView: WMFEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapReference(toolbarView: WMFEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapLink(toolbarView: WMFEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapShowMore(toolbarView: WMFEditorToolbarHighlightView)
}

class WMFEditorToolbarHighlightView: WMFEditorToolbarView {
    
    // MARK: - Properties
    
    @IBOutlet private weak var stackView: UIStackView!
    
    @IBOutlet private weak var boldButton: WMFEditorToolbarButton!
    @IBOutlet private weak var italicsButton: WMFEditorToolbarButton!
    @IBOutlet private weak var referenceButton: WMFEditorToolbarButton!
    @IBOutlet private weak var linkButton: WMFEditorToolbarButton!
    @IBOutlet private weak var templateButton: WMFEditorToolbarButton!
    @IBOutlet private weak var showMoreButton: WMFEditorToolbarNavigatorButton!
    
    weak var delegate: WMFEditorToolbarHighlightViewDelegate?
    
    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        
        boldButton.setImage(WMFSFSymbolIcon.for(symbol: .bold))
        boldButton.addTarget(self, action: #selector(tappedBold), for: .touchUpInside)
        boldButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current?.toolbarBoldButtonAccessibility

        italicsButton.setImage(WMFSFSymbolIcon.for(symbol: .italic))
        italicsButton.addTarget(self, action: #selector(tappedItalics), for: .touchUpInside)
        italicsButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current?.toolbarItalicsButtonAccessibility

        referenceButton.setImage(WMFSFSymbolIcon.for(symbol: .quoteOpening))
        referenceButton.addTarget(self, action: #selector(tappedReference), for: .touchUpInside)
        referenceButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current?.toolbarReferenceButtonAccessibility

        linkButton.setImage(WMFSFSymbolIcon.for(symbol: .link))
        linkButton.addTarget(self, action: #selector(tappedLink), for: .touchUpInside)
        linkButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current?.toolbarLinkButtonAccessibility

        templateButton.setImage(WMFSFSymbolIcon.for(symbol: .curlybraces))
        templateButton.addTarget(self, action: #selector(tappedTemplate), for: .touchUpInside)
        templateButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current?.toolbarTemplateButtonAccessibility
        showMoreButton.setImage(WMFSFSymbolIcon.for(symbol: .plusCircleFill), for: .normal)
        showMoreButton.addTarget(self, action: #selector(tappedShowMore), for: .touchUpInside)
        showMoreButton.accessibilityIdentifier = WMFSourceEditorAccessibilityIdentifiers.current?.showMoreButton
        showMoreButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current?.toolbarOpenTextFormatMenuButtonAccessibility
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonSelectionState(_:)), name: Notification.WMFSourceEditorSelectionState, object: nil)
        
        accessibilityElements = [boldButton as Any, italicsButton as Any, referenceButton as Any, linkButton as Any, templateButton as Any, showMoreButton as Any]
    }
    
    // MARK: - Notifications
    
    @objc private func updateButtonSelectionState(_ notification: NSNotification) {
        guard let selectionState = notification.userInfo?[Notification.WMFSourceEditorSelectionStateKey] as? WMFSourceEditorSelectionState else {
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
