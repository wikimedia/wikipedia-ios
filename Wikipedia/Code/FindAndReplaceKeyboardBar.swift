//
//  FindAndReplaceKeyboardBar.swift
//  Wikipedia
//
//  Created by Toni Sevener on 3/12/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit

@objc (WMFFindAndReplaceKeyboardBarDelegate)
protocol FindAndReplaceKeyboardBarDelegate: class {
    func keyboardBar(_ keyboardBar: FindAndReplaceKeyboardBar, didChangeSearchTerm searchTerm: String?)
    func keyboardBarDidTapClose(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapClear(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapPrevious(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapNext(_ keyboardBar: FindAndReplaceKeyboardBar?)
    func keyboardBarDidTapReturn(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapReplace(_ keyboardBar: FindAndReplaceKeyboardBar, replaceText: String, replaceType: ReplaceType)
}

protocol FindAndReplaceKeyboardBarDisplayDelegate: class {
    func keyboardBarDidTapReplaceSwitch(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidShow(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidHide(_ keyboardBar: FindAndReplaceKeyboardBar)
}

@objc enum ReplaceType: Int {
    case replaceSingle
    case replaceAll
}

@objc (WMFFindAndReplaceKeyboardBar)
final class FindAndReplaceKeyboardBar: UIInputView {
    @IBOutlet private var outerStackView: UIStackView!
    @IBOutlet var outerStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var outerStackViewTrailingConstraint: NSLayoutConstraint!
    
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
    
    private var currentMatchTotal: UInt = 0
    
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
        get {
            return findTextField.isFirstResponder || replaceTextField.isFirstResponder
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tintColor = UIColor.wmf_darkGray
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        hideUndoRedoIcons()
        previousButton.isEnabled = false
        nextButton.isEnabled = false
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        updateShowingReplaceState()
        updateReplaceLabelState()
        updateReplaceButtonsState()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 46)
    }
    
    @objc func updateMatchCounts(index: Int, total: UInt) {
        currentMatchTotal = total
        updateMatchCountLabel(index: index, total: total)
        updatePreviousNextButtonsState(total: total)
        updateReplaceButtonsState()
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
        resetReplace()
    }
    
    @objc func resetFind() {
        findTextField.text = nil
        currentMatchLabel.text = nil
        findClearButton.isHidden = true
        currentMatchTotal = 0
        updateMatchCounts(index: 0, total: 0)
        updatePreviousNextButtonsState(total: 0)
    }
    
    //MARK: IBActions
    
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

//MARK: UITextFieldDelegate

extension FindAndReplaceKeyboardBar: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField {
        case findTextField:
             delegate?.keyboardBarDidTapReturn(self)
        case replaceTextField:
            
            guard let replaceText = replaceTextField.text,
                let findText = findTextField.text,
                currentMatchTotal > 0,
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

//MARK: Themeable

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

//MARK: Private

private extension FindAndReplaceKeyboardBar {
    
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
    
    func updateMatchCountLabel(index: Int, total: UInt) {
        
        guard let findText = findTextField.text,
            findText.count > 0 else {
                currentMatchLabel.text = nil
                return
        }
        
        var labelText: String
        if total > 0 && index == -1 {
            labelText = String.localizedStringWithFormat("%lu", total)
        } else {
            let format = WMFLocalizedStringWithDefaultValue("find-in-page-number-matches", nil, nil, "%1$@ / %2$@", "Displayed to indicate how many matches were found even if no matches. Separator can be customized depending on the language. %1$@ is replaced with the numerator, %2$@ is replaced with the denominator.")
            labelText = String.localizedStringWithFormat(format, NSNumber(value: index + 1), NSNumber(value: total))
        }
        
        currentMatchLabel.text = labelText
    }
    
    func updatePreviousNextButtonsState(total: UInt) {
        previousButton.isEnabled = total >= 2
        nextButton.isEnabled = total >= 2
    }
    
    func updateReplaceLabelState() {
        #warning("todo: localize")
        
        let count = replaceTextField.text?.count ?? 0
        replacePlaceholderLabel.text = "Replace with..."
        
        var replaceTypeText: String
        switch replaceType {
        case .replaceSingle: replaceTypeText = "Replace"
        case .replaceAll: replaceTypeText = "Replace all"
        }
        
        switch (replaceTextField.isFirstResponder, count) {
        case (false, 0):
            replaceTypeLabel.text = nil //niling out so longer placeholder strings will bump up against the X button
            replaceTypeLabel.isHidden = true
            replacePlaceholderLabel.isHidden = false
        case (true, 0):
            replaceTypeLabel.text = nil
            replaceTypeLabel.isHidden = true
            replacePlaceholderLabel.isHidden = true
        case (_, 1...):
            replaceTypeLabel.text = replaceTypeText
            replaceTypeLabel.isHidden = false
            replacePlaceholderLabel.isHidden = true
        default:
            assertionFailure("Unexpected replace label state")
        }
    }
    
    func updateReplaceButtonsState() {
        let count = replaceTextField.text?.count ?? 0
        replaceButton.isEnabled = count > 0 && currentMatchTotal > 0
        replaceSwitchButton.isEnabled = count > 0 || replaceTextField.isFirstResponder
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
    }
}
