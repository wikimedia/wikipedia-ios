import UIKit

protocol WKEditorToolbarHighlightViewDelegate: AnyObject {
    func toolbarHighlightViewDidTapBold(toolbarView: WKEditorToolbarHighlightView, isSelected: Bool)
    func toolbarHighlightViewDidTapItalics(toolbarView: WKEditorToolbarHighlightView, isSelected: Bool)
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
        accessibilityElements = buttons + [showMoreButton as Any]
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        
        boldButton.setImage(WKIcon.bold, for: .normal)
        boldButton.addTarget(self, action: #selector(tappedBold), for: .touchUpInside)
        boldButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonBold

        italicsButton.setImage(WKIcon.italics, for: .normal)
        italicsButton.addTarget(self, action: #selector(tappedItalics), for: .touchUpInside)
        italicsButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonItalics

        formatHeadingButton.setImage(WKIcon.formatHeading, for: .normal)
        formatHeadingButton.addTarget(self, action: #selector(tappedFormatHeading), for: .touchUpInside)
        formatHeadingButton.accessibilityIdentifier = WKSourceEditorAccessibilityIdentifiers.current?.formatHeadingButton
        formatHeadingButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonFormatHeading

        citationButton.setImage(WKIcon.citation, for: .normal)
        citationButton.addTarget(self, action: #selector(tappedCitation), for: .touchUpInside)
        citationButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonCitation

        linkButton.setImage(WKIcon.link, for: .normal)
        linkButton.addTarget(self, action: #selector(tappedLink), for: .touchUpInside)
        linkButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonLink

        templateButton.setImage(WKIcon.template, for: .normal)
        templateButton.addTarget(self, action: #selector(tappedTemplate), for: .touchUpInside)
        templateButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonTemplate

        clearMarkupButton.setImage(WKIcon.clear, for: .normal)
        clearMarkupButton.addTarget(self, action: #selector(tappedClearMarkup), for: .touchUpInside)
        clearMarkupButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonClearFormatting

        showMoreButton.setImage(WKIcon.plusCircle, for: .normal)
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
    }
    
    // MARK: - Button Actions

    @objc private func tappedBold() {
        delegate?.toolbarHighlightViewDidTapBold(toolbarView: self, isSelected: boldButton.isSelected)
    }

    @objc private func tappedItalics() {
        delegate?.toolbarHighlightViewDidTapItalics(toolbarView: self, isSelected: italicsButton.isSelected)
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
