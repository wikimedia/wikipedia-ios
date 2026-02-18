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
    @IBOutlet var legacyOuterContainer: UIView!
    @IBOutlet private var legacyOuterStackView: UIStackView!
    @IBOutlet var legacyOuterStackViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet private var legacyFindStackView: UIStackView!
    @IBOutlet private var legacyFindTextField: UITextField!
    @IBOutlet private var legacyFindTextFieldContainer: UIView!
    @IBOutlet private var legacyMagnifyImageView: UIImageView!
    @IBOutlet private var legacyCurrentMatchLabel: UILabel!
    @IBOutlet private var legacyFindClearButton: UIButton!
    @IBOutlet private var legacyCloseButton: UIButton!
    @IBOutlet private var legacyNextButton: UIButton!
    @IBOutlet private var legacyNextPrevButtonStackView: UIStackView!
    @IBOutlet private var legacyPreviousButton: UIButton!
    
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
                legacyCurrentMatchLabel.text = String.localizedStringWithFormat("%lu", matchPlacement.total)
            } else if let index = matchPlacement.index {
                let format = WMFLocalizedString("find-infolabel-number-matches", value: "%1$@ / %2$@", comment: "Displayed to indicate how many matches were found even if no matches. Separator can be customized depending on the language. %1$@ is replaced with the numerator, %2$@ is replaced with the denominator.")
                legacyCurrentMatchLabel.text = String.localizedStringWithFormat(format, NSNumber(value: index), NSNumber(value: matchPlacement.total))
            }
        }
    }
    
    @objc var isVisible: Bool {
        return legacyFindTextField.isFirstResponder
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        hideUndoRedoIcons()
        legacyPreviousButton.isEnabled = false
        legacyNextButton.isEnabled = false
        
        setupStaticAccessibilityLabels()
        
//        if #available(iOS 26.0, *) {
//            setupForLiquidGlass()
//        } else {
//            // Fallback on earlier versions
//        }
    }
//    
//    @available(iOS 26.0, *)
//    private func setupForLiquidGlass() {
//    
//         // Clear the background so the glass effect shows through
//        legacyOuterContainer.backgroundColor = .clear
//        
//        // Create and configure the glass effect view
//        let effectView = UIVisualEffectView(frame: legacyOuterContainer.bounds)
//        let glassEffect = UIGlassEffect(style: .regular)
//        self.glassEffect = glassEffect
//        effectView.effect = glassEffect
//        
//        // Make sure it resizes with the container
//        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        
//        // Insert at the bottom so content appears on top
//        legacyOuterContainer.insertSubview(effectView, at: 0)
//        
//        // Apply corner radius for rounded edges
//        effectView.layer.cornerRadius = intrinsicContentSize.height / 2
//        effectView.clipsToBounds = true
//        legacyOuterContainer.layer.cornerRadius = intrinsicContentSize.height / 2
//        legacyOuterContainer.clipsToBounds = true
//        
//        // Adjust spacing
//        legacyOuterStackViewTopConstraint.constant = 0
//    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 46)
    }
    
    @objc func updateMatchCounts(index: Int, total: UInt) {
        updateMatchPlacement(index: index, total: total)
        updatePreviousNextButtonsState(total: total)
    }
    
    @objc func show() {
        legacyFindTextField.becomeFirstResponder()
        displayDelegate?.keyboardBarDidShow(self)
    }
    
    @objc func hide() {
        legacyFindTextField.resignFirstResponder()
        displayDelegate?.keyboardBarDidHide(self)
    }
    
    func reset() {
        resetFind()
    }
    
    @objc func resetFind() {
        legacyFindTextField.text = nil
        legacyCurrentMatchLabel.text = nil
        legacyFindClearButton.isHidden = true
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
        case legacyFindTextField:
            delegate?.keyboardBar(self, didChangeSearchTerm: legacyFindTextField.text)
            legacyFindClearButton.isHidden = count == 0
        default:
            break
        }
    }
}

// MARK: UITextFieldDelegate

extension FindAndReplaceKeyboardBar: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
        case legacyFindTextField:
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
    
        legacyFindTextField.keyboardAppearance = theme.keyboardAppearance
        legacyFindTextField.textColor = theme.colors.primaryText
        legacyFindTextFieldContainer.backgroundColor = theme.colors.keyboardBarSearchFieldBackground
        legacyCloseButton.tintColor = theme.colors.secondaryText
        legacyPreviousButton.tintColor = theme.colors.secondaryText
        legacyNextButton.tintColor = theme.colors.secondaryText
        legacyMagnifyImageView.tintColor = theme.colors.secondaryText
        legacyFindClearButton.tintColor = theme.colors.secondaryText
        legacyCurrentMatchLabel.textColor = theme.colors.tertiaryText
    }
}

// MARK: Private

private extension FindAndReplaceKeyboardBar {
    
    func setupStaticAccessibilityLabels() {
        legacyFindTextField.accessibilityLabel = WMFLocalizedString("find-textfield-accessibility", value: "Find", comment: "Accessibility label for the find text field.")
        legacyFindClearButton.accessibilityLabel = WMFLocalizedString("find-clear-button-accessibility", value: "Clear find", comment: "Accessibility label for the clear values X button in the find textfield.")
        legacyCloseButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        legacyNextButton.accessibilityLabel = WMFLocalizedString("find-next-button-accessibility", value: "Next find result", comment: "Accessibility label for the next button when traversing find results.")
        legacyPreviousButton.accessibilityLabel = WMFLocalizedString("find-previous-button-accessibility", value: "Previous find result", comment: "Accessibility label for the previous button when traversing find results.")
    }
    
    func hideUndoRedoIcons() {
        if legacyFindTextField.responds(to: #selector(getter: inputAssistantItem)) {
            legacyFindTextField.inputAssistantItem.leadingBarButtonGroups = []
            legacyFindTextField.inputAssistantItem.trailingBarButtonGroups = []
        }
    }
    
    func updateMatchPlacement(index: Int, total: UInt) {
        
        guard let findText = legacyFindTextField.text,
            findText.count > 0 else {
                legacyCurrentMatchLabel.text = nil
                return
        }
        
        if total > 0 && index == -1 {
            matchPlacement = FindMatchPlacement(index: nil, total: total)
        } else {
            matchPlacement = FindMatchPlacement(index: UInt(max(0, index + 1)), total: total)
        }
    }
    
    func updatePreviousNextButtonsState(total: UInt) {
        legacyPreviousButton.isEnabled = total >= 2
        legacyNextButton.isEnabled = total >= 2
    }
}
