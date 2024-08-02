import UIKit

protocol WMFEditorToolbarExpandingViewDelegate: AnyObject {
    func toolbarExpandingViewDidTapFind(toolbarView: WMFEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapFormatText(toolbarView: WMFEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapTemplate(toolbarView: WMFEditorToolbarExpandingView, isSelected: Bool)
    func toolbarExpandingViewDidTapReference(toolbarView: WMFEditorToolbarExpandingView, isSelected: Bool)
    func toolbarExpandingViewDidTapLink(toolbarView: WMFEditorToolbarExpandingView, isSelected: Bool)
    func toolbarExpandingViewDidTapImage(toolbarView: WMFEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapUnorderedList(toolbarView: WMFEditorToolbarExpandingView, isSelected: Bool)
    func toolbarExpandingViewDidTapOrderedList(toolbarView: WMFEditorToolbarExpandingView, isSelected: Bool)
    func toolbarExpandingViewDidTapIncreaseIndent(toolbarView: WMFEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapDecreaseIndent(toolbarView: WMFEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapCursorUp(toolbarView: WMFEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapCursorDown(toolbarView: WMFEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapCursorLeft(toolbarView: WMFEditorToolbarExpandingView)
    func toolbarExpandingViewDidTapCursorRight(toolbarView: WMFEditorToolbarExpandingView)
}

class WMFEditorToolbarExpandingView: WMFEditorToolbarView {
    
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

    @IBOutlet private weak var formatTextButton: WMFEditorToolbarButton!
    @IBOutlet private weak var referenceButton: WMFEditorToolbarButton!
    @IBOutlet private weak var linkButton: WMFEditorToolbarButton!
    @IBOutlet private weak var templateButton: WMFEditorToolbarButton!
    @IBOutlet private weak var imageButton: WMFEditorToolbarButton!
    @IBOutlet private weak var findInPageButton: WMFEditorToolbarButton!
    
    @IBOutlet private weak var unorderedListButton: WMFEditorToolbarButton!
    @IBOutlet private weak var orderedListButton: WMFEditorToolbarButton!
    @IBOutlet private weak var decreaseIndentionButton: WMFEditorToolbarButton!
    @IBOutlet private weak var increaseIndentionButton: WMFEditorToolbarButton!
    @IBOutlet private weak var cursorUpButton: WMFEditorToolbarButton!
    @IBOutlet private weak var cursorDownButton: WMFEditorToolbarButton!
    @IBOutlet private weak var cursorLeftButton: WMFEditorToolbarButton!
    @IBOutlet private weak var cursorRightButton: WMFEditorToolbarButton!
    
    @IBOutlet private weak var expandButton: WMFEditorToolbarNavigatorButton!
    
    weak var delegate: WMFEditorToolbarExpandingViewDelegate?
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)

        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            stackView.removeArrangedSubview(primaryContainerView)
            stackView.addArrangedSubview(primaryContainerView)
        }

        expandButton.setImage(WMFSFSymbolIcon.for(symbol: .chevronRightCircle), for: .normal)
        expandButton.addTarget(self, action: #selector(tappedExpand), for: .touchUpInside)
        expandButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarExpandButtonAccessibility
        updateExpandButtonVisibility()

        formatTextButton.setImage(WMFSFSymbolIcon.for(symbol: .textFormat))
        formatTextButton.addTarget(self, action: #selector(tappedFormatText), for: .touchUpInside)
        formatTextButton.accessibilityIdentifier = WMFSourceEditorAccessibilityIdentifiers.current?.formatTextButton
        formatTextButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarOpenTextFormatMenuButtonAccessibility

        referenceButton.setImage(WMFSFSymbolIcon.for(symbol: .quoteOpening))
        referenceButton.addTarget(self, action: #selector(tappedReference), for: .touchUpInside)
        referenceButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarReferenceButtonAccessibility

        linkButton.setImage(WMFSFSymbolIcon.for(symbol: .link))
        linkButton.addTarget(self, action: #selector(tappedLink), for: .touchUpInside)
        linkButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarLinkButtonAccessibility

        templateButton.setImage(WMFSFSymbolIcon.for(symbol: .curlybraces))
        templateButton.addTarget(self, action: #selector(tappedTemplate), for: .touchUpInside)
        templateButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarTemplateButtonAccessibility

        imageButton.setImage(WMFSFSymbolIcon.for(symbol: .photo))
        imageButton.addTarget(self, action: #selector(tappedMedia), for: .touchUpInside)
        imageButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarImageButtonAccessibility

        findInPageButton.setImage(WMFSFSymbolIcon.for(symbol: .docTextMagnifyingGlass))
        findInPageButton.addTarget(self, action: #selector(tappedFindInPage), for: .touchUpInside)
        findInPageButton.accessibilityIdentifier = WMFSourceEditorAccessibilityIdentifiers.current?.findButton
        findInPageButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarFindButtonAccessibility

        unorderedListButton.setImage(WMFSFSymbolIcon.for(symbol: .listBullet))
        unorderedListButton.addTarget(self, action: #selector(tappedUnorderedList), for: .touchUpInside)
        unorderedListButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarListUnorderedButtonAccessibility

        orderedListButton.setImage(WMFSFSymbolIcon.for(symbol: .listNumber))
        orderedListButton.addTarget(self, action: #selector(tappedOrderedList), for: .touchUpInside)
        orderedListButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarListOrderedButtonAccessibility

        decreaseIndentionButton.setImage(WMFSFSymbolIcon.for(symbol: .decreaseIndent))
        decreaseIndentionButton.addTarget(self, action: #selector(tappedDecreaseIndentation), for: .touchUpInside)
        decreaseIndentionButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarIndentDecreaseButtonAccessibility
        decreaseIndentionButton.isEnabled = false

        increaseIndentionButton.setImage(WMFSFSymbolIcon.for(symbol: .increaseIndent))
        increaseIndentionButton.addTarget(self, action: #selector(tappedIncreaseIndentation), for: .touchUpInside)
        increaseIndentionButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarIndentIncreaseButtonAccessibility
        increaseIndentionButton.isEnabled = false

        cursorUpButton.setImage(WMFSFSymbolIcon.for(symbol: .chevronUp))
        cursorUpButton.addTarget(self, action: #selector(tappedCursorUp), for: .touchUpInside)
        cursorUpButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarCursorUpButtonAccessibility

        cursorDownButton.setImage(WMFSFSymbolIcon.for(symbol: .chevronDown))
        cursorDownButton.addTarget(self, action: #selector(tappedCursorDown), for: .touchUpInside)
        cursorDownButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarCursorDownButtonAccessibility

        cursorLeftButton.setImage(WMFSFSymbolIcon.for(symbol: .chevronBackward))
        cursorLeftButton.addTarget(self, action: #selector(tappedCursorLeft), for: .touchUpInside)
        cursorLeftButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarCursorPreviousButtonAccessibility

        cursorRightButton.setImage(WMFSFSymbolIcon.for(symbol: .chevronForward))
        cursorRightButton.addTarget(self, action: #selector(tappedCursorRight), for: .touchUpInside)
        cursorRightButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.toolbarCursorNextButtonAccessibility
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonSelectionState(_:)), name: Notification.WMFSourceEditorSelectionState, object: nil)
    }
    
    // MARK: - Overrides
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateExpandButtonVisibility()
    }
    
    // MARK: - Notifications
    
    @objc private func updateButtonSelectionState(_ notification: NSNotification) {
        guard let selectionState = notification.userInfo?[Notification.WMFSourceEditorSelectionStateKey] as? WMFSourceEditorSelectionState else {
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
