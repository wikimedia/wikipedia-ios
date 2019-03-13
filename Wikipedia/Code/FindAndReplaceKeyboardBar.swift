//
//  FindAndReplaceKeyboardBar.swift
//  Wikipedia
//
//  Created by Toni Sevener on 3/12/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit

@objc (WMFFindAndReplaceKeyboardBarDelegate)
protocol FindAndReplaceKeyboardBarDelegate {
    func keyboardBar(_ keyboardBar: FindAndReplaceKeyboardBar, didChangeSearchTerm searchTerm: String?)
    func keyboardBarDidTapClose(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapClear(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapPrevious(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapNext(_ keyboardBar: FindAndReplaceKeyboardBar)
    func keyboardBarDidTapReturn(_ keyboardBar: FindAndReplaceKeyboardBar)
}

@objc (WMFFindAndReplaceKeyboardBar)
class FindAndReplaceKeyboardBar: UIInputView {

    @IBOutlet private var textField: UITextField!
    @IBOutlet private var textFieldContainer: UIView!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var clearButton: UIButton!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var previousButton: UIButton!
    @IBOutlet private var currentMatchLabel: UILabel!
    @IBOutlet private var magnifyImageView: UIImageView!
    
    weak var delegate: FindAndReplaceKeyboardBarDelegate?
    
    var isVisible: Bool {
        get {
            return textField.isFirstResponder
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
        textField.becomeFirstResponder()
    }
    
    func hide() {
        textField.resignFirstResponder()
    }
    
    func reset() {
        textField.text = nil
        currentMatchLabel.text = nil
        clearButton.isHidden = true
    }
    
    @IBAction func tappedClear() {
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
        
        delegate?.keyboardBar(self, didChangeSearchTerm: textField.text)
        
        let count = textField.text?.count ?? 0
        clearButton.isHidden = count == 0
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
        textField.keyboardAppearance = theme.keyboardAppearance
        textField.textColor = theme.colors.primaryText
        textFieldContainer.backgroundColor = theme.colors.keyboardBarSearchFieldBackground
        tintColor = theme.colors.link
        closeButton.tintColor = theme.colors.secondaryText
        previousButton.tintColor = theme.colors.secondaryText
        nextButton.tintColor = theme.colors.secondaryText
        magnifyImageView.tintColor = theme.colors.secondaryText
        clearButton.tintColor = theme.colors.secondaryText
        currentMatchLabel.textColor = theme.colors.tertiaryText
    }
}

//MARK: Private

private extension FindAndReplaceKeyboardBar {
    func hideUndoRedoIcons() {
        if textField.responds(to: #selector(getter: inputAssistantItem)) {
            textField.inputAssistantItem.leadingBarButtonGroups = []
            textField.inputAssistantItem.trailingBarButtonGroups = []
        }
    }
    
    func updateMatchCountLabel(index: Int, total: UInt) {
        
        guard let findText = textField.text,
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

