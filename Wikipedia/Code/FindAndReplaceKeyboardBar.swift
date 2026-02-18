import UIKit

@objc(WMFFindAndReplaceKeyboardBarDelegate)
protocol FindAndReplaceKeyboardBarDelegate: AnyObject {
    func keyboardBar(_ keyboardBar: FindAndReplaceKeyboardBar, didChangeSearchTerm searchTerm: String?)
    func keyboardBarDidTapClose(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapClear(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapPrevious(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapNext(_ keyboardBar: FindAndReplaceKeyboardBar?)
    func keyboardBarDidTapReturn(_ keyboardBar: FindAndReplaceKeyboardBar)
}

protocol FindAndReplaceKeyboardBarDisplayDelegate: AnyObject {
    func keyboardBarDidShow(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidHide(_ keyboardBar: FindAndReplaceKeyboardBar)
}

struct FindMatchPlacement {
    var index: UInt?
    var total: UInt
}

@objc(WMFFindAndReplaceKeyboardBar)
final class FindAndReplaceKeyboardBar: UIInputView {
    @IBOutlet var outerContainer: UIView!
    @IBOutlet private var outerStackView: UIStackView!
    @IBOutlet private var outerStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var outerStackViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var outerStackViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet private var findStackView: UIStackView!
    @IBOutlet private var findTextField: UITextField!
    @IBOutlet private var findTextFieldContainer: UIView!
    @IBOutlet private var magnifyImageView: UIImageView!
    @IBOutlet private var currentMatchLabel: UILabel!
    @IBOutlet private var findClearButton: UIButton!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var nextPrevButtonStackView: UIStackView!
    @IBOutlet private var previousButton: UIButton!
    
    @objc weak var delegate: FindAndReplaceKeyboardBarDelegate?
    weak var displayDelegate: FindAndReplaceKeyboardBarDisplayDelegate?
    
    private var _glassEffect: Any? = nil
    @available(iOS 26, *)
    private var glassEffect: UIGlassEffect? {
        get {
            return _glassEffect as? UIGlassEffect
        }
        set {
            _glassEffect = newValue
        }
        
    }
    
    // represents current match label values
    private var matchPlacement = FindMatchPlacement(index: 0, total: 0) {
        didSet {
            if matchPlacement.index == nil && matchPlacement.total > 0 {
                currentMatchLabel.text = String.localizedStringWithFormat("%lu", matchPlacement.total)
            } else if let index = matchPlacement.index {
                let format = WMFLocalizedString("find-infolabel-number-matches", value: "%1$@ / %2$@", comment: "Displayed to indicate how many matches were found even if no matches. Separator can be customized depending on the language. %1$@ is replaced with the numerator, %2$@ is replaced with the denominator.")
                currentMatchLabel.text = String.localizedStringWithFormat(format, NSNumber(value: index), NSNumber(value: matchPlacement.total))
            }
        }
    }
    
    @objc var isVisible: Bool {
        return findTextField.isFirstResponder
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        hideUndoRedoIcons()
        previousButton.isEnabled = false
        nextButton.isEnabled = false
        
        setupStaticAccessibilityLabels()
        
        if #available(iOS 26.0, *) {
            setupForLiquidGlass()
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 26.0, *)
    private func setupForLiquidGlass() {
    
         // Clear the background so the glass effect shows through
        outerContainer.backgroundColor = .clear
        
        // Create and configure the glass effect view
        let effectView = UIVisualEffectView(frame: outerContainer.bounds)
        let glassEffect = UIGlassEffect(style: .regular)
        self.glassEffect = glassEffect
        effectView.effect = glassEffect
        
        // Make sure it resizes with the container
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Insert at the bottom so content appears on top
        outerContainer.insertSubview(effectView, at: 0)
        
        // Apply corner radius for rounded edges
        effectView.layer.cornerRadius = intrinsicContentSize.height / 2
        effectView.clipsToBounds = true
        outerContainer.layer.cornerRadius = intrinsicContentSize.height / 2
        outerContainer.clipsToBounds = true
        
        // Adjust spacing
        outerStackViewTopConstraint.constant = 0
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 46)
    }
    
    @objc func updateMatchCounts(index: Int, total: UInt) {
        updateMatchPlacement(index: index, total: total)
        updatePreviousNextButtonsState(total: total)
    }
    
    @objc func show() {
        findTextField.becomeFirstResponder()
        displayDelegate?.keyboardBarDidShow(self)
    }
    
    @objc func hide() {
        findTextField.resignFirstResponder()
        displayDelegate?.keyboardBarDidHide(self)
    }
    
    func reset() {
        resetFind()
    }
    
    @objc func resetFind() {
        findTextField.text = nil
        currentMatchLabel.text = nil
        findClearButton.isHidden = true
        matchPlacement.index = 0
        matchPlacement.total = 0
        updateMatchCounts(index: 0, total: 0)
        updatePreviousNextButtonsState(total: 0)
    }
    
    // MARK: IBActions
    
    @IBAction func tappedFindClear() {
        delegate?.keyboardBarDidTapClear(self)
        if !isVisible {
            show()
        }
    }
    
    @IBAction func tappedClose() {
        delegate?.keyboardBarDidTapClose(self)
    }
    
    @IBAction func tappedNext() {
        delegate?.keyboardBarDidTapNext(self)
    }
    
    @IBAction func tappedPrevious() {
        delegate?.keyboardBarDidTapPrevious(self)
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        let count = sender.text?.count ?? 0
        
        switch sender {
        case findTextField:
            delegate?.keyboardBar(self, didChangeSearchTerm: findTextField.text)
            findClearButton.isHidden = count == 0
        default:
            break
        }
    }
}

// MARK: UITextFieldDelegate

extension FindAndReplaceKeyboardBar: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
        case findTextField:
             delegate?.keyboardBarDidTapReturn(self)
        default:
            break
        }
       
        return true
    }
}

// MARK: Themeable

extension FindAndReplaceKeyboardBar: Themeable {
    func apply(theme: Theme) {
        tintColor = theme.colors.link
        
        if #available(iOS 26, *) {
            findTextField.keyboardAppearance = theme.keyboardAppearance
            findTextField.textColor = theme.colors.primaryText
            findTextFieldContainer.backgroundColor = .clear
            closeButton.tintColor = theme.colors.secondaryText
            previousButton.tintColor = theme.colors.secondaryText
            nextButton.tintColor = theme.colors.secondaryText
            magnifyImageView.tintColor = theme.colors.secondaryText
            findClearButton.tintColor = theme.colors.secondaryText
            currentMatchLabel.textColor = theme.colors.tertiaryText
            glassEffect?.tintColor = theme.colors.midBackground
        } else {
            findTextField.keyboardAppearance = theme.keyboardAppearance
            findTextField.textColor = theme.colors.primaryText
            findTextFieldContainer.backgroundColor = theme.colors.keyboardBarSearchFieldBackground
            closeButton.tintColor = theme.colors.secondaryText
            previousButton.tintColor = theme.colors.secondaryText
            nextButton.tintColor = theme.colors.secondaryText
            magnifyImageView.tintColor = theme.colors.secondaryText
            findClearButton.tintColor = theme.colors.secondaryText
            currentMatchLabel.textColor = theme.colors.tertiaryText
        }
    }
}

// MARK: Private

private extension FindAndReplaceKeyboardBar {
    
    func setupStaticAccessibilityLabels() {
        findTextField.accessibilityLabel = WMFLocalizedString("find-textfield-accessibility", value: "Find", comment: "Accessibility label for the find text field.")
        findClearButton.accessibilityLabel = WMFLocalizedString("find-clear-button-accessibility", value: "Clear find", comment: "Accessibility label for the clear values X button in the find textfield.")
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        nextButton.accessibilityLabel = WMFLocalizedString("find-next-button-accessibility", value: "Next find result", comment: "Accessibility label for the next button when traversing find results.")
        previousButton.accessibilityLabel = WMFLocalizedString("find-previous-button-accessibility", value: "Previous find result", comment: "Accessibility label for the previous button when traversing find results.")
    }
    
    func hideUndoRedoIcons() {
        if findTextField.responds(to: #selector(getter: inputAssistantItem)) {
            findTextField.inputAssistantItem.leadingBarButtonGroups = []
            findTextField.inputAssistantItem.trailingBarButtonGroups = []
        }
    }
    
    func updateMatchPlacement(index: Int, total: UInt) {
        
        guard let findText = findTextField.text,
            findText.count > 0 else {
                currentMatchLabel.text = nil
                return
        }
        
        if total > 0 && index == -1 {
            matchPlacement = FindMatchPlacement(index: nil, total: total)
        } else {
            matchPlacement = FindMatchPlacement(index: UInt(max(0, index + 1)), total: total)
        }
    }
    
    func updatePreviousNextButtonsState(total: UInt) {
        previousButton.isEnabled = total >= 2
        nextButton.isEnabled = total >= 2
    }
}

#if TEST
// MARK: Helpers for testing
extension FindAndReplaceKeyboardBar {
    func setFindTextForTesting(_ text: String) {
        findTextField.text = text
        textFieldDidChange(findTextField)
    }
    
    func setReplaceTextForTesting(_ text: String) {
        replaceTextField.text = text
        textFieldDidChange(replaceTextField)
    }
    
    func tapNextForTesting() {
        tappedNext()
    }
    
    func tapReplaceForTesting() {
        tappedReplace()
    }
    
    var matchPlacementForTesting: FindMatchPlacement {
        return matchPlacement
    }
}
#endif
