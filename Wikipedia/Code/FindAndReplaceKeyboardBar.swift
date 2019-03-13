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

protocol FindAndReplaceKeyboardBarAlertDelegate: class {
    func keyboardBarDidTapReplaceSwitch(_ keyboardBar: FindAndReplaceKeyboardBar)
}

@objc enum ReplaceType: Int {
    case replaceSingle
    case replaceAll
}

@objc (WMFFindAndReplaceKeyboardBar)
class FindAndReplaceKeyboardBar: UIInputView {
    @IBOutlet private var outerStackView: UIStackView!
    
    @IBOutlet private var findStackView: UIStackView!
    @IBOutlet private var findTextField: UITextField!
    @IBOutlet private var findTextFieldContainer: UIView!
    @IBOutlet private var magnifyImageView: UIImageView!
    @IBOutlet private var currentMatchLabel: UILabel!
    @IBOutlet private var findClearButton: UIButton!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var previousButton: UIButton!
   
    @IBOutlet private var replaceStackView: UIStackView!
    @IBOutlet private var replaceTextField: UITextField!
    @IBOutlet private var replaceTextFieldContainer: UIView!
    @IBOutlet private var pencilImageView: UIImageView!
    @IBOutlet private var replaceLabel: UILabel!
    @IBOutlet private var replaceClearButton: UIButton!
    @IBOutlet private var replaceButton: UIButton!
    @IBOutlet private var replaceSwitchButton: UIButton!
    
    @objc weak var delegate: FindAndReplaceKeyboardBarDelegate?
    weak var alertDelegate: FindAndReplaceKeyboardBarAlertDelegate?
    
    var replaceType: ReplaceType = .replaceSingle {
        didSet {
            if oldValue != replaceType {
                updateReplaceTypeState()
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
        updateReplaceTypeState()
        updateShowingReplaceState()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 46)
    }
    
    @objc func updateMatchCounts(index: Int, total: UInt) {
        updateMatchCountLabel(index: index, total: total)
        updatePreviousNextButtonsState(total: total)
    }
    
    @objc func show() {
        findTextField.becomeFirstResponder()
    }
    
    @objc func hide() {
        findTextField.resignFirstResponder()
    }
    
    @objc func resetFind() {
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
        delegate?.keyboardBarDidTapReplace(self, replaceText: replaceText, replaceType: replaceType)
    }
    
    @IBAction func tappedReplaceSwitch() {
        #warning("todo: set replace enable/disable button states")
        alertDelegate?.keyboardBarDidTapReplaceSwitch(self)
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        let count = sender.text?.count ?? 0
        
        switch sender {
        case findTextField:
            delegate?.keyboardBar(self, didChangeSearchTerm: findTextField.text)
            findClearButton.isHidden = count == 0
        case replaceTextField:
            replaceClearButton.isHidden = count == 0
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
        default:
            break
        }
       
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
    
    func updatePreviousNextButtonsState(total: UInt) {
        previousButton.isEnabled = total > 2
        nextButton.isEnabled = total > 2
    }
    
    func updateReplaceTypeState() {
        
        #warning("todo: localize")
        
        switch replaceType {
        case .replaceSingle: replaceLabel.text = "Replace"
        case .replaceAll: replaceLabel.text = "Replace all"
        }
    }
    
    func updateShowingReplaceState() {
        
        if isShowingReplace {
            replaceStackView.isHidden = false
            closeButton.isHidden = true
            findStackView.addArrangedSubview(previousButton)
            findStackView.addArrangedSubview(nextButton)
        } else {
            replaceStackView.isHidden = true
            closeButton.isHidden = false
            findStackView.insertArrangedSubview(previousButton, at: 0)
             findStackView.insertArrangedSubview(nextButton, at: 1)
        }
    }
}

