import UIKit

protocol WKEditorToolbarExpandingViewDelegate: AnyObject {
    func toolbarExpandingViewDidTapFind(toolbarView: WKEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapFormatText(toolbarView: WKEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapTemplate(toolbarView: WKEditorToolbarExpandingView, isSelected: Bool)
    func toolbarExpandingViewDidTapReference(toolbarView: WKEditorToolbarExpandingView, isSelected: Bool)
    func toolbarExpandingViewDidTapLink(toolbarView: WKEditorToolbarExpandingView, isSelected: Bool)
    func toolbarExpandingViewDidTapImage(toolbarView: WKEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapUnorderedList(toolbarView: WKEditorToolbarExpandingView, isSelected: Bool)
    func toolbarExpandingViewDidTapOrderedList(toolbarView: WKEditorToolbarExpandingView, isSelected: Bool)
    func toolbarExpandingViewDidTapIncreaseIndent(toolbarView: WKEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapDecreaseIndent(toolbarView: WKEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapCursorUp(toolbarView: WKEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapCursorDown(toolbarView: WKEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapCursorLeft(toolbarView: WKEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapCursorRight(toolbarView: WKEditorToolbarExpandingView)
}

class WKEditorToolbarExpandingView: WKEditorToolbarView {
    
    // MARK: - Nested Types
    
    private enum ActionsType: CGFloat {
        case primary
        case secondary

        static func visible(rawValue: RawValue) -> ActionsType {
            if rawValue == 0 {
                return .primary
            } else {
                return .secondary
            }
        }

        static func next(rawValue: RawValue) -> ActionsType {
            if rawValue == 0 {
                return .secondary
            } else {
                return .primary
            }
        }
    }
    
    // MARK: - Properties
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet weak var primaryContainerView: UIView!
    @IBOutlet weak var secondaryContainerView: UIView!

    @IBOutlet private weak var formatTextButton: WKEditorToolbarButton!
    @IBOutlet private weak var referenceButton: WKEditorToolbarButton!
    @IBOutlet private weak var linkButton: WKEditorToolbarButton!
    @IBOutlet private weak var templateButton: WKEditorToolbarButton!
    @IBOutlet private weak var imageButton: WKEditorToolbarButton!
    @IBOutlet private weak var findInPageButton: WKEditorToolbarButton!
    
    @IBOutlet private weak var unorderedListButton: WKEditorToolbarButton!
    @IBOutlet private weak var orderedListButton: WKEditorToolbarButton!
    @IBOutlet private weak var decreaseIndentionButton: WKEditorToolbarButton!
    @IBOutlet private weak var increaseIndentionButton: WKEditorToolbarButton!
    @IBOutlet private weak var cursorUpButton: WKEditorToolbarButton!
    @IBOutlet private weak var cursorDownButton: WKEditorToolbarButton!
    @IBOutlet private weak var cursorLeftButton: WKEditorToolbarButton!
    @IBOutlet private weak var cursorRightButton: WKEditorToolbarButton!
    
    @IBOutlet private weak var expandButton: WKEditorToolbarNavigatorButton!
    
    weak var delegate: WKEditorToolbarExpandingViewDelegate?
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)

        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            stackView.removeArrangedSubview(primaryContainerView)
            stackView.addArrangedSubview(primaryContainerView)
        }

        expandButton.setImage(WKSFSymbolIcon.for(symbol: .chevronRightCircle), for: .normal)
        expandButton.addTarget(self, action: #selector(tappedExpand), for: .touchUpInside)
        expandButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarExpandButtonAccessibility
        updateExpandButtonVisibility()

        formatTextButton.setImage(WKSFSymbolIcon.for(symbol: .textFormat))
        formatTextButton.addTarget(self, action: #selector(tappedFormatText), for: .touchUpInside)
        formatTextButton.accessibilityIdentifier = WKSourceEditorAccessibilityIdentifiers.current?.formatTextButton
        formatTextButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarOpenTextFormatMenuButtonAccessibility

        referenceButton.setImage(WKSFSymbolIcon.for(symbol: .quoteOpening))
        referenceButton.addTarget(self, action: #selector(tappedReference), for: .touchUpInside)
        referenceButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarReferenceButtonAccessibility

        linkButton.setImage(WKSFSymbolIcon.for(symbol: .link))
        linkButton.addTarget(self, action: #selector(tappedLink), for: .touchUpInside)
        linkButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarLinkButtonAccessibility

        templateButton.setImage(WKSFSymbolIcon.for(symbol: .curlybraces))
        templateButton.addTarget(self, action: #selector(tappedTemplate), for: .touchUpInside)
        templateButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarTemplateButtonAccessibility

        imageButton.setImage(WKSFSymbolIcon.for(symbol: .photo))
        imageButton.addTarget(self, action: #selector(tappedMedia), for: .touchUpInside)
        imageButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarImageButtonAccessibility

        findInPageButton.setImage(WKSFSymbolIcon.for(symbol: .docTextMagnifyingGlass))
        findInPageButton.addTarget(self, action: #selector(tappedFindInPage), for: .touchUpInside)
        findInPageButton.accessibilityIdentifier = WKSourceEditorAccessibilityIdentifiers.current?.findButton
        findInPageButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarFindButtonAccessibility

        unorderedListButton.setImage(WKSFSymbolIcon.for(symbol: .listBullet))
        unorderedListButton.addTarget(self, action: #selector(tappedUnorderedList), for: .touchUpInside)
        unorderedListButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarListUnorderedButtonAccessibility

        orderedListButton.setImage(WKSFSymbolIcon.for(symbol: .listNumber))
        orderedListButton.addTarget(self, action: #selector(tappedOrderedList), for: .touchUpInside)
        orderedListButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarListOrderedButtonAccessibility

        decreaseIndentionButton.setImage(WKSFSymbolIcon.for(symbol: .decreaseIndent))
        decreaseIndentionButton.addTarget(self, action: #selector(tappedDecreaseIndentation), for: .touchUpInside)
        decreaseIndentionButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarIndentDecreaseButtonAccessibility
        decreaseIndentionButton.isEnabled = false

        increaseIndentionButton.setImage(WKSFSymbolIcon.for(symbol: .increaseIndent))
        increaseIndentionButton.addTarget(self, action: #selector(tappedIncreaseIndentation), for: .touchUpInside)
        increaseIndentionButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarIndentIncreaseButtonAccessibility
        increaseIndentionButton.isEnabled = false

        cursorUpButton.setImage(WKSFSymbolIcon.for(symbol: .chevronUp))
        cursorUpButton.addTarget(self, action: #selector(tappedCursorUp), for: .touchUpInside)
        cursorUpButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarCursorUpButtonAccessibility

        cursorDownButton.setImage(WKSFSymbolIcon.for(symbol: .chevronDown))
        cursorDownButton.addTarget(self, action: #selector(tappedCursorDown), for: .touchUpInside)
        cursorDownButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarCursorDownButtonAccessibility

        cursorLeftButton.setImage(WKSFSymbolIcon.for(symbol: .chevronBackward))
        cursorLeftButton.addTarget(self, action: #selector(tappedCursorLeft), for: .touchUpInside)
        cursorLeftButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarCursorPreviousButtonAccessibility

        cursorRightButton.setImage(WKSFSymbolIcon.for(symbol: .chevronForward))
        cursorRightButton.addTarget(self, action: #selector(tappedCursorRight), for: .touchUpInside)
        cursorRightButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current.toolbarCursorNextButtonAccessibility
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonSelectionState(_:)), name: Notification.WKSourceEditorSelectionState, object: nil)
    }
    
    // MARK: - Overrides
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateExpandButtonVisibility()
    }
    
    // MARK: - Notifications
    
    @objc private func updateButtonSelectionState(_ notification: NSNotification) {
        guard let selectionState = notification.userInfo?[Notification.WKSourceEditorSelectionStateKey] as? WKSourceEditorSelectionState else {
            return
        }
        
        templateButton.isSelected = selectionState.isHorizontalTemplate
        referenceButton.isSelected = selectionState.isHorizontalReference
        linkButton.isSelected = selectionState.isSimpleLink
        imageButton.isEnabled = !selectionState.isBold && !selectionState.isItalics && !selectionState.isSimpleLink
        
        unorderedListButton.isSelected = selectionState.isBulletSingleList || selectionState.isBulletMultipleList
        unorderedListButton.isEnabled = !selectionState.isNumberSingleList && !selectionState.isNumberMultipleList
        
        orderedListButton.isSelected = selectionState.isNumberSingleList || selectionState.isNumberMultipleList
        orderedListButton.isEnabled = !selectionState.isBulletSingleList && !selectionState.isBulletMultipleList
        
        decreaseIndentionButton.isEnabled = false
        if selectionState.isBulletMultipleList || selectionState.isNumberMultipleList {
            decreaseIndentionButton.isEnabled = true
        }
        
        if selectionState.isBulletSingleList ||
            selectionState.isBulletMultipleList ||
            selectionState.isNumberSingleList ||
            selectionState.isNumberMultipleList {
            increaseIndentionButton.isEnabled = true
        } else {
            increaseIndentionButton.isEnabled = false
        }
    }

    // MARK: - Button Actions
    
    @objc private func tappedExpand() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        let offsetX = scrollView.contentOffset.x
        let actionsType = ActionsType.next(rawValue: offsetX)
        
        let transform = CGAffineTransform.identity
        let buttonTransform: () -> Void
        let newOffsetX: CGFloat
        
        let sender = expandButton

        switch actionsType {
        case .primary:
            buttonTransform = {
                sender?.transform = transform
            }
            newOffsetX = 0
        case .secondary:
            buttonTransform = {
                sender?.transform = transform.rotated(by: 180 * CGFloat.pi)
                sender?.transform = transform.rotated(by: -1 * CGFloat.pi)
            }
            newOffsetX = stackView.bounds.width / 2
        }

        let scrollViewContentOffsetChange = {
            self.scrollView.setContentOffset(CGPoint(x: newOffsetX , y: 0), animated: false)
        }

        let buttonAnimator = UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.7, animations: buttonTransform)
        let scrollViewAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeInOut, animations: scrollViewContentOffsetChange)
        scrollViewAnimator.addCompletion { [weak self] _ in
            self?.updateExpandButtonVisibility()
        }

        buttonAnimator.startAnimation()
        scrollViewAnimator.startAnimation()
    }

    @objc private func tappedFormatText() {
        delegate?.toolbarExpandingViewDidTapFormatText(toolbarView: self)
    }

    @objc private func tappedReference() {
        delegate?.toolbarExpandingViewDidTapReference(toolbarView: self, isSelected: referenceButton.isSelected)
    }

    @objc private func tappedLink() {
        delegate?.toolbarExpandingViewDidTapLink(toolbarView: self, isSelected: linkButton.isSelected)
    }

    @objc private func tappedUnorderedList() {
        delegate?.toolbarExpandingViewDidTapUnorderedList(toolbarView: self, isSelected: unorderedListButton.isSelected)
    }

    @objc private func tappedOrderedList() {
        delegate?.toolbarExpandingViewDidTapOrderedList(toolbarView: self, isSelected: orderedListButton.isSelected)
    }

    @objc private func tappedDecreaseIndentation() {
        delegate?.toolbarExpandingViewDidTapDecreaseIndent(toolbarView: self)
    }

    @objc private func tappedIncreaseIndentation() {
        delegate?.toolbarExpandingViewDidTapIncreaseIndent(toolbarView: self)
    }

    @objc private func tappedCursorUp() {
        delegate?.toolbarExpandingViewDidTapCursorUp(toolbarView: self)
    }

    @objc private func tappedCursorDown() {
        delegate?.toolbarExpandingViewDidTapCursorDown(toolbarView: self)
    }

    @objc private func tappedCursorLeft() {
        delegate?.toolbarExpandingViewDidTapCursorLeft(toolbarView: self)
    }

    @objc private func tappedCursorRight() {
        delegate?.toolbarExpandingViewDidTapCursorRight(toolbarView: self)
    }

    @objc private func tappedTemplate() {
        delegate?.toolbarExpandingViewDidTapTemplate(toolbarView: self, isSelected: templateButton.isSelected)
    }

    @objc private func tappedFindInPage() {
        delegate?.toolbarExpandingViewDidTapFind(toolbarView: self)
    }

    @objc private func tappedMedia() {
        delegate?.toolbarExpandingViewDidTapImage(toolbarView: self)
    }
    
    // MARK: - Private Helpers
    
    private func updateExpandButtonVisibility() {
        expandButton.isHidden = traitCollection.horizontalSizeClass == .regular
        
        if expandButton.isHidden {
            accessibilityElements = [formatTextButton as Any, referenceButton as Any, linkButton as Any, templateButton as Any, imageButton as Any, findInPageButton as Any, unorderedListButton as Any, orderedListButton as Any, decreaseIndentionButton as Any, increaseIndentionButton as Any, cursorUpButton as Any, cursorDownButton as Any, cursorLeftButton as Any, cursorRightButton as Any]
            UIAccessibility.post(notification: .screenChanged, argument: formatTextButton)
        } else {
            if scrollView.contentOffset.x == 0 {
                accessibilityElements = [formatTextButton as Any, referenceButton as Any, linkButton as Any, templateButton as Any, imageButton as Any, findInPageButton as Any, expandButton as Any]
                UIAccessibility.post(notification: .screenChanged, argument: formatTextButton)
            } else {
                accessibilityElements = [unorderedListButton as Any, orderedListButton as Any, decreaseIndentionButton as Any, increaseIndentionButton as Any, cursorUpButton as Any, cursorDownButton as Any, cursorLeftButton as Any, cursorRightButton as Any, expandButton as Any]
                UIAccessibility.post(notification: .screenChanged, argument: unorderedListButton)
            }
        }
    }

}
