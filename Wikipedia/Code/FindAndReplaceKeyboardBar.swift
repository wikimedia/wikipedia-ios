//
//  FindAndReplaceKeyboardBar.swift
//  Wikipedia
//
//  Created by Toni Sevener on 3/12/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit

protocol FindAndReplaceKeyboardBarDelegate: class {
    func keyboardBar(_ keyboardBar: FindAndReplaceKeyboardBar, didChangeSearchTerm searchTerm: String?)
    func keyboardBarDidTapClose(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapClear(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapPrevious(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapNext(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapReturn(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapReplace(_ keyboardBar: FindAndReplaceKeyboardBar, replaceText: String, replaceState: ReplaceState)
}

protocol FindAndReplaceKeyboardBarAlertDelegate: class {
    func keyboardBarDidTapReplaceSwitch(_ keyboardBar: FindAndReplaceKeyboardBar)
}

enum ReplaceState {
    case replace
    case replaceAll
}

@objc (WMFFindAndReplaceKeyboardBar)
class FindAndReplaceKeyboardBar: UIInputView {
    @IBOutlet private var findTextField: UITextField!
    @IBOutlet private var findTextFieldContainer: UIView!
    @IBOutlet private var replaceTextField: UITextField!
    @IBOutlet private var replaceTextFieldContainer: UIView!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var findClearButton: UIButton!
    @IBOutlet private var replaceClearButton: UIButton!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var previousButton: UIButton!
    @IBOutlet private var currentMatchLabel: UILabel!
    @IBOutlet private var magnifyImageView: UIImageView!
    
    var replaceState: ReplaceState = .replace {
        didSet {
            #warning("todo: update replace/replace all info label here")
        }
    }
    
    weak var delegate: FindAndReplaceKeyboardBarDelegate?
    weak var alertDelegate: FindAndReplaceKeyboardBarAlertDelegate?
    
    var isVisible: Bool {
        get {
            return findTextField.isFirstResponder
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
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 46)
    }
    
    func updateMatchCounts(index: Int, total: UInt) {
        updateMatchCountLabel(index: index, total: total)
        updatePreviousNextButtonsEnabled(total: total)
    }
    
    func show() {
        findTextField.becomeFirstResponder()
    }
    
    func hide() {
        findTextField.resignFirstResponder()
    }
    
    func reset() {
        findTextField.text = nil
        currentMatchLabel.text = nil
        findClearButton.isHidden = true
    }
    
    @IBAction func tappedFindClear() {
        delegate?.keyboardBarDidTapClear(self)
        if !isVisible {
            show()
        }
    }
    
    @IBAction func tappedReplaceClear() {
        replaceTextField.text = nil
        replaceClearButton.isHidden = true
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
        
        #warning("todo: set replace enable/disable button states")
        guard let replaceText = replaceTextField.text else {
            return
        }
        delegate?.keyboardBarDidTapReplace(self, replaceText: replaceText, replaceState: replaceState)
    }
    
    @IBAction func tappedReplaceSwitch() {
        #warning("todo: set replace enable/disable button states")
        alertDelegate?.keyboardBarDidTapReplaceSwitch(self)
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        let count = sender.text?.count ?? 0
        
        if sender == findTextField {
            delegate?.keyboardBar(self, didChangeSearchTerm: findTextField.text)
            findClearButton.isHidden = count == 0
        } else {
            replaceClearButton.isHidden = count == 0
        }
    }
}

//MARK: UITextFieldDelegate

extension FindAndReplaceKeyboardBar: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.keyboardBarDidTapReturn(self)
        return true
    }
}

//MARK: Themeable

extension FindAndReplaceKeyboardBar: Themeable {
    func apply(theme: Theme) {
        findTextField.keyboardAppearance = theme.keyboardAppearance
        findTextField.textColor = theme.colors.primaryText
        findTextFieldContainer.backgroundColor = theme.colors.keyboardBarSearchFieldBackground
        tintColor = theme.colors.link
        closeButton.tintColor = theme.colors.secondaryText
        previousButton.tintColor = theme.colors.secondaryText
        nextButton.tintColor = theme.colors.secondaryText
        magnifyImageView.tintColor = theme.colors.secondaryText
        findClearButton.tintColor = theme.colors.secondaryText
        currentMatchLabel.textColor = theme.colors.tertiaryText
    }
}

//MARK: Private

private extension FindAndReplaceKeyboardBar {
    func hideUndoRedoIcons() {
        if findTextField.responds(to: #selector(getter: inputAssistantItem)) {
            findTextField.inputAssistantItem.leadingBarButtonGroups = []
            findTextField.inputAssistantItem.trailingBarButtonGroups = []
        }
    }
    
    func updateMatchCountLabel(index: Int, total: UInt) {
        
        guard let findText = findTextField.text,
            findText.count > 0 else {
                currentMatchLabel.text = nil
                return
        }
        
        #warning("todo: try to use optional instead of -1")
        
        var labelText: String
        if total > 0 && index == -1 {
            labelText = String.localizedStringWithFormat("%lu", total)
        } else {
            let format = WMFLocalizedStringWithDefaultValue("find-in-page-number-matches", nil, nil, "%1$@ / %2$@", "Displayed to indicate how many matches were found even if no matches. Separator can be customized depending on the language. %1$@ is replaced with the numerator, %2$@ is replaced with the denominator.")
            labelText = String.localizedStringWithFormat(format, NSNumber(value: index + 1), NSNumber(value: total))
        }
        
        currentMatchLabel.text = labelText
    }
    
    func updatePreviousNextButtonsEnabled(total: UInt) {
        previousButton.isEnabled = total > 2
        nextButton.isEnabled = total > 2
    }
}

