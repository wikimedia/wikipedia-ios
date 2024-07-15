import UIKit

@objc(WMFFindAndReplaceKeyboardBarDelegate)
protocol FindAndReplaceKeyboardBarDelegate: AnyObject {
    func keyboardBar(_ keyboardBar: FindAndReplaceKeyboardBar, didChangeSearchTerm searchTerm: String?)
    func keyboardBarDidTapClose(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapClear(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapPrevious(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapNext(_ keyboardBar: FindAndReplaceKeyboardBar?)
    func keyboardBarDidTapReturn(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapReplace(_ keyboardBar: FindAndReplaceKeyboardBar, replaceText: String, replaceType: ReplaceType)
}

protocol FindAndReplaceKeyboardBarDisplayDelegate: AnyObject {
    func keyboardBarDidTapReplaceSwitch(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidShow(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidHide(_ keyboardBar: FindAndReplaceKeyboardBar)
}

@objc enum ReplaceType: Int {
    case replaceSingle
    case replaceAll
    
    var text: String {
        switch self {
        case .replaceSingle: return WMFLocalizedString("replace-infolabel-method-replace", value: "Replace", comment: "Title for label indicating which replace method they have currently selected. This is for replacing a single instance.")
        case .replaceAll: return WMFLocalizedString("replace-infolabel-method-replace-all", value: "Replace all", comment: "Title for label indicating which replace method they have currently selected. This is for replacing all instances.")
        }
    }
    
    var accessibilityText: String {
        switch self {
        case .replaceSingle: return WMFLocalizedString("replace-buttons-replace-accessibility", value: "Replace single instance", comment: "Accessibility text for describing the type of replace the user is set to or about to perform. This is for replacing a single instance.")
        case .replaceAll: return WMFLocalizedString("replace-buttons-replace-all-accessibility", value: "Replace all instances", comment: "Accessibility text for describing the type of replace the user is set to or about to perform. This is for replacing all instances.")
        }
    }
}

struct FindMatchPlacement {
    var index: UInt?
    var total: UInt
}

@objc(WMFFindAndReplaceKeyboardBar)
final class FindAndReplaceKeyboardBar: UIInputView {
    @IBOutlet private var outerStackView: UIStackView!
    @IBOutlet private var outerStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var outerStackViewTrailingConstraint: NSLayoutConstraint!
    
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
   
    @IBOutlet private var replaceStackView: UIStackView!
    @IBOutlet private var replaceTextField: UITextField!
    @IBOutlet private var replaceTextFieldContainer: UIView!
    @IBOutlet private var pencilImageView: UIImageView!
    @IBOutlet private var replaceTypeLabel: UILabel!
    @IBOutlet private var replacePlaceholderLabel: UILabel!
    @IBOutlet private var replaceClearButton: UIButton!
    @IBOutlet private var replaceButton: UIButton!
    @IBOutlet private(set) var replaceSwitchButton: UIButton!
    
    @objc weak var delegate: FindAndReplaceKeyboardBarDelegate?
    weak var displayDelegate: FindAndReplaceKeyboardBarDisplayDelegate?
    
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
    
    var replaceType: ReplaceType = .replaceSingle {
        didSet {
            if oldValue != replaceType {
                updateReplaceLabelState()
            }
        }
    }
    
    var isShowingReplace: Bool = false {
        didSet {
            if oldValue != isShowingReplace {
                updateShowingReplaceState()
            }
        }
    }
    
    @objc var isVisible: Bool {
        return findTextField.isFirstResponder || replaceTextField.isFirstResponder
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        hideUndoRedoIcons()
        previousButton.isEnabled = false
        nextButton.isEnabled = false
        
        setupStaticAccessibilityLabels()
        
        updateShowingReplaceState()
        updateReplaceLabelState()
        updateReplaceButtonsState()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 46)
    }
    
    @objc func updateMatchCounts(index: Int, total: UInt) {
        updateMatchPlacement(index: index, total: total)
        updatePreviousNextButtonsState(total: total)
        updateReplaceButtonsState()
    }
    
    @objc func show() {
        findTextField.becomeFirstResponder()
        displayDelegate?.keyboardBarDidShow(self)
    }
    
    @objc func hide() {
        findTextField.resignFirstResponder()
        replaceTextField.resignFirstResponder()
        displayDelegate?.keyboardBarDidHide(self)
    }
    
    func reset() {
        resetFind()
        resetReplace()
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
    
    @IBAction func tappedReplaceClear() {
        replaceTextField.text = nil
        updateReplaceLabelState()
        updateReplaceButtonsState()
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
    
    @IBAction func tappedReplace() {
        
        guard let replaceText = replaceTextField.text else {
            return
        }
        delegate?.keyboardBarDidTapReplace(self, replaceText: replaceText, replaceType: replaceType)
    }
    
    @IBAction func tappedReplaceSwitch() {
        displayDelegate?.keyboardBarDidTapReplaceSwitch(self)
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        let count = sender.text?.count ?? 0
        
        switch sender {
        case findTextField:
            delegate?.keyboardBar(self, didChangeSearchTerm: findTextField.text)
            findClearButton.isHidden = count == 0
            updateReplaceButtonsState()
        case replaceTextField:
            updateReplaceButtonsState()
            updateReplaceLabelState()
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
        case replaceTextField:
            
            guard let replaceText = replaceTextField.text,
                let findText = findTextField.text,
                matchPlacement.total > 0,
                findText.count > 0,
                replaceText.count > 0 else {
                return false
            }
            
            delegate?.keyboardBarDidTapReplace(self, replaceText: replaceText, replaceType: replaceType)
        default:
            break
        }
       
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateReplaceLabelState()
        updateReplaceButtonsState()
    }
}

// MARK: Themeable

extension FindAndReplaceKeyboardBar: Themeable {
    func apply(theme: Theme) {
        tintColor = theme.colors.link
        
        findTextField.keyboardAppearance = theme.keyboardAppearance
        findTextField.textColor = theme.colors.primaryText
        findTextFieldContainer.backgroundColor = theme.colors.keyboardBarSearchFieldBackground
        closeButton.tintColor = theme.colors.secondaryText
        previousButton.tintColor = theme.colors.secondaryText
        nextButton.tintColor = theme.colors.secondaryText
        magnifyImageView.tintColor = theme.colors.secondaryText
        findClearButton.tintColor = theme.colors.secondaryText
        currentMatchLabel.textColor = theme.colors.tertiaryText
        
        replaceTextField.keyboardAppearance = theme.keyboardAppearance
        replaceTextField.textColor = theme.colors.primaryText
        replaceTextFieldContainer.backgroundColor = theme.colors.keyboardBarSearchFieldBackground
        replaceButton.tintColor = theme.colors.secondaryText
        replaceSwitchButton.tintColor = theme.colors.secondaryText
        pencilImageView.tintColor = theme.colors.secondaryText
        replaceClearButton.tintColor = theme.colors.secondaryText
        replaceTypeLabel.textColor = theme.colors.tertiaryText
        replacePlaceholderLabel.textColor = theme.colors.tertiaryText
        
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
        replaceTextField.accessibilityLabel = WMFLocalizedString("replace-textfield-accessibility", value: "Replace", comment: "Accessibility label for the replace text field.")
        replaceTypeLabel.isAccessibilityElement = false
        replacePlaceholderLabel.isAccessibilityElement = false
        replaceClearButton.accessibilityLabel = WMFLocalizedString("replace-clear-button-accessibility", value: "Clear replace", comment: "Accessibility label for the clear values X button in the replace textfield.")
    }
    
    func hideUndoRedoIcons() {
        if findTextField.responds(to: #selector(getter: inputAssistantItem)) {
            findTextField.inputAssistantItem.leadingBarButtonGroups = []
            findTextField.inputAssistantItem.trailingBarButtonGroups = []
        }
        
        if replaceTextField.responds(to: #selector(getter: inputAssistantItem)) {
            replaceTextField.inputAssistantItem.leadingBarButtonGroups = []
            replaceTextField.inputAssistantItem.trailingBarButtonGroups = []
        }
    }
    
    func resetReplace() {
        replaceTextField.text = nil
        replaceType = .replaceSingle
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
    
    func updateReplaceLabelState() {
        
        let count = replaceTextField.text?.count ?? 0
        replacePlaceholderLabel.text = WMFLocalizedString("replace-textfield-placeholder", value: "Replace with…", comment: "Placeholder text seen in replace textfield before textfield is focused.")
        
        switch (replaceTextField.isFirstResponder, count) {
        case (false, 0):
            replaceTypeLabel.text = nil // niling out so longer placeholder strings will bump up against the X button
            replaceTypeLabel.isHidden = true
            replacePlaceholderLabel.isHidden = false
        case (true, 0):
            replaceTypeLabel.text = nil
            replaceTypeLabel.isHidden = true
            replacePlaceholderLabel.isHidden = true
        case (_, 1...):
            replaceTypeLabel.text = replaceType.text
            replaceTypeLabel.isHidden = false
            replacePlaceholderLabel.isHidden = true
        default:
            assertionFailure("Unexpected replace label state")
        }
        
        let replaceMethodAccessibleFormat = WMFLocalizedString("replace-method-button-accessibility", value: "Replace method. Set to %1$@. Select to change.", comment: "Accessibility label for replace method switch button in Find and Replace. %1$@ is replaced by \"Replace single instance\" or \"Replace all instances\"")
        replaceSwitchButton.accessibilityLabel = String.localizedStringWithFormat(replaceMethodAccessibleFormat, replaceType.accessibilityText)
        
        let replaceAccessibleFormat = WMFLocalizedString("replace-button-accessibility", value: "Perform %1$@.", comment: "Accessibility label for button that triggers replace action. %1$@ is replaced by \"Replace single instance\" or \"Replace all instances\"")
        replaceButton.accessibilityLabel = String.localizedStringWithFormat(replaceAccessibleFormat, replaceType.accessibilityText)
    }
    
    func updateReplaceButtonsState() {
        let count = replaceTextField.text?.count ?? 0
        replaceButton.isEnabled = count > 0 && matchPlacement.total > 0 && replaceTextField.text != findTextField.text
        replaceClearButton.isHidden = count == 0
    }
    
    func updateShowingReplaceState() {
        
        if isShowingReplace {
            replaceStackView.isHidden = false
            closeButton.isHidden = true
            findStackView.addArrangedSubview(nextPrevButtonStackView)
            outerStackViewLeadingConstraint.constant = 18
            outerStackViewTrailingConstraint.constant = 18
        } else {
            replaceStackView.isHidden = true
            closeButton.isHidden = false
            findStackView.insertArrangedSubview(nextPrevButtonStackView, at: 0)
            outerStackViewLeadingConstraint.constant = 10
            outerStackViewTrailingConstraint.constant = 5
        }
        if isShowingReplace {
            accessibilityElements = [findTextField, currentMatchLabel, findClearButton, previousButton, nextButton, replaceTextField, replaceClearButton, replaceButton, replaceSwitchButton].compactMap { $0 as Any }
        } else {
            accessibilityElements = [previousButton, nextButton, findTextField, currentMatchLabel, findClearButton, closeButton].compactMap { $0 as Any }
        }
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
