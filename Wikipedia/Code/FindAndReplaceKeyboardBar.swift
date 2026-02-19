import UIKit
import WMFComponents
import SwiftUI

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
    @IBOutlet private var legacyFindTextFieldContainer: UIView!
    @IBOutlet private var legacyFindTextField: UITextField!
    @IBOutlet private var legacyMagnifyImageView: UIImageView!
    @IBOutlet private var legacyCurrentMatchLabel: UILabel!
    @IBOutlet private var legacyFindClearButton: UIButton!
    @IBOutlet private var legacyCloseButton: UIButton!
    @IBOutlet private var legacyNextButton: UIButton!
    @IBOutlet private var legacyPreviousButton: UIButton!
    
    @IBOutlet var modernOuterContainer: UIView!
    @IBOutlet var modernOuterStackView: UIStackView!
    @IBOutlet var modernFindTextfieldContainer: UIView!
    @IBOutlet var modernMagnifyImageView: UIImageView!
    @IBOutlet var modernFindTextField: UITextField!
    @IBOutlet var modernCurrentMatchLabel: UILabel!
    @IBOutlet var modernFindClearButton: UIButton!
    
    @IBOutlet var modernCloseButton: UIButton!
    private var modernNextButton: UIButton?
    private var modernPrevButton: UIButton?
    
    @objc weak var delegate: FindAndReplaceKeyboardBarDelegate?
    weak var displayDelegate: FindAndReplaceKeyboardBarDisplayDelegate?
    
    private var textfieldEffectView: UIVisualEffectView?
    private var nextPrevButtonEffectView: UIVisualEffectView?
    
    // represents current match label values
    private var matchPlacement = FindMatchPlacement(index: 0, total: 0) {
        didSet {
            let format = WMFLocalizedString("find-infolabel-number-matches", value: "%1$@ / %2$@", comment: "Displayed to indicate how many matches were found even if no matches. Separator can be customized depending on the language. %1$@ is replaced with the numerator, %2$@ is replaced with the denominator.")
            if #available(iOS 26.0, *) {
                if matchPlacement.index == nil && matchPlacement.total > 0 {
                    modernCurrentMatchLabel.text = String.localizedStringWithFormat("%lu", matchPlacement.total)
                } else if let index = matchPlacement.index {
                    modernCurrentMatchLabel.text = String.localizedStringWithFormat(format, NSNumber(value: index), NSNumber(value: matchPlacement.total))
                }
            } else {
                if matchPlacement.index == nil && matchPlacement.total > 0 {
                    legacyCurrentMatchLabel.text = String.localizedStringWithFormat("%lu", matchPlacement.total)
                } else if let index = matchPlacement.index {
                    legacyCurrentMatchLabel.text = String.localizedStringWithFormat(format, NSNumber(value: index), NSNumber(value: matchPlacement.total))
                }
            }

        }
    }
    
    @objc var isVisible: Bool {
        if #available(iOS 26.0, *) {
            return modernFindTextField.isFirstResponder
        } else {
            return legacyFindTextField.isFirstResponder
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        hideUndoRedoIcons()
        
        
        setupStaticAccessibilityLabels()
        
        if #available(iOS 26.0, *) {
            setupForLiquidGlass()
            modernPrevButton?.isEnabled = false
            modernNextButton?.isEnabled = false
        } else {
            setupForLegacyView()
            legacyPreviousButton.isEnabled = false
            legacyNextButton.isEnabled = false
        }
    }
    
    private func setupForLegacyView() {
        modernOuterContainer.removeFromSuperview()
    }
    
    @available(iOS 26.0, *)
    private func setupForLiquidGlass() {
        
        legacyOuterContainer.removeFromSuperview()
        backgroundColor = .clear

       modernOuterContainer.backgroundColor = .clear

        let textfieldEffectView = UIVisualEffectView()
        textfieldEffectView.translatesAutoresizingMaskIntoConstraints = false
        let glassEffect = UIGlassEffect(style: .regular)
        textfieldEffectView.effect = glassEffect
        self.textfieldEffectView = textfieldEffectView

        // Insert at the bottom so content appears on top
        modernFindTextfieldContainer.insertSubview(textfieldEffectView, at: 0)
        
        NSLayoutConstraint.activate([
            modernFindTextfieldContainer.leadingAnchor.constraint(equalTo: textfieldEffectView.leadingAnchor),
            modernFindTextfieldContainer.trailingAnchor.constraint(equalTo: textfieldEffectView.trailingAnchor),
            modernFindTextfieldContainer.topAnchor.constraint(equalTo: textfieldEffectView.topAnchor),
            modernFindTextfieldContainer.bottomAnchor.constraint(equalTo: textfieldEffectView.bottomAnchor)
        ])
        
        modernMagnifyImageView.image = WMFSFSymbolIcon.for(symbol: .docTextMagnifyingGlass)
        modernFindClearButton.setImage(WMFSFSymbolIcon.for(symbol: .closeButtonFill, font: .boldBody), for: .normal)
        
        modernCloseButton.configuration = .prominentGlass()
        modernCloseButton.setImage(WMFSFSymbolIcon.for(symbol: .checkmark, font: .semiboldSubheadline), for: .normal)
        
        // custom prev/next buttons
        let buttonContainerView = UIView()
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        buttonContainerView.backgroundColor = .clear

        var prevConfig = UIButton.Configuration.plain()
        prevConfig.image = WMFSFSymbolIcon.for(symbol: .chevronUp)
        let prevButton = UIButton(configuration: prevConfig, primaryAction: nil)
        prevButton.addTarget(self, action: #selector(tappedPrevious), for: .touchUpInside)
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        prevButton.addTarget(self, action: #selector(tappedPrevious), for: .touchUpInside)
        self.modernPrevButton = prevButton
        
        var nextConfig = UIButton.Configuration.plain()
        nextConfig.image = WMFSFSymbolIcon.for(symbol: .chevronDown)
        let nextButton = UIButton(configuration: nextConfig, primaryAction: nil)
        nextButton.addTarget(self, action: #selector(tappedNext), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(tappedNext), for: .touchUpInside)
        self.modernNextButton = nextButton
        
        buttonContainerView.addSubview(prevButton)
        buttonContainerView.addSubview(nextButton)
        
        let buttonEffectView = UIVisualEffectView()
        buttonEffectView.translatesAutoresizingMaskIntoConstraints = false
        buttonEffectView.effect = glassEffect
        buttonEffectView.tintColor = Theme.light.colors.midBackground
        buttonContainerView.insertSubview(buttonEffectView, at: 0)
        self.nextPrevButtonEffectView = buttonEffectView
        
        modernOuterStackView.addArrangedSubview(buttonContainerView)
        
        NSLayoutConstraint.activate([
            buttonContainerView.heightAnchor.constraint(equalTo: modernFindTextfieldContainer.heightAnchor),
            buttonContainerView.leadingAnchor.constraint(equalTo: buttonEffectView.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: buttonEffectView.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: buttonEffectView.bottomAnchor),
            buttonContainerView.topAnchor.constraint(equalTo: buttonEffectView.topAnchor),
            buttonContainerView.leadingAnchor.constraint(equalTo: prevButton.leadingAnchor),
            buttonContainerView.topAnchor.constraint(equalTo: prevButton.topAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: prevButton.bottomAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: nextButton.trailingAnchor),
            buttonContainerView.topAnchor.constraint(equalTo: nextButton.topAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: nextButton.bottomAnchor),
            prevButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Apply corner radius for rounded edges
        textfieldEffectView?.layer.cornerRadius = modernFindTextfieldContainer.frame.height / 2
        textfieldEffectView?.clipsToBounds = true
        nextPrevButtonEffectView?.layer.cornerRadius = (nextPrevButtonEffectView?.frame.height ?? 0) / 2
        nextPrevButtonEffectView?.clipsToBounds = true
        modernFindTextfieldContainer.layer.cornerRadius = modernFindTextfieldContainer.frame.height / 2
        modernFindTextfieldContainer.clipsToBounds = true
    }
    
    override var intrinsicContentSize: CGSize {
        if #available(iOS 26.0, *) {
            return CGSize(width: UIView.noIntrinsicMetric, height: 58)
        } else {
            return CGSize(width: UIView.noIntrinsicMetric, height: 46)
        }
    }
    
    @objc func updateMatchCounts(index: Int, total: UInt) {
        updateMatchPlacement(index: index, total: total)
        updatePreviousNextButtonsState(total: total)
    }
    
    @objc func show() {
        if #available(iOS 26.0, *) {
            modernFindTextField.becomeFirstResponder()
            displayDelegate?.keyboardBarDidShow(self)
        } else {
            legacyFindTextField.becomeFirstResponder()
            displayDelegate?.keyboardBarDidShow(self)
        }
        
    }
    
    @objc func hide() {
        if #available(iOS 26.0, *) {
            modernFindTextField.resignFirstResponder()
            displayDelegate?.keyboardBarDidHide(self)
        } else {
            legacyFindTextField.resignFirstResponder()
            displayDelegate?.keyboardBarDidHide(self)
        }
    }
    
    func reset() {
        resetFind()
    }
    
    @objc func resetFind() {
        if #available(iOS 26.0, *) {
            modernFindTextField.text = nil
            modernCurrentMatchLabel.text = nil
            modernFindClearButton.isHidden = true
        } else {
            legacyFindTextField.text = nil
            legacyCurrentMatchLabel.text = nil
            legacyFindClearButton.isHidden = true
        }

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
        case modernFindTextField:
            delegate?.keyboardBar(self, didChangeSearchTerm: modernFindTextField.text)
            modernFindClearButton.isHidden = count == 0
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
        case modernFindTextField:
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
        if #available(iOS 26.0, *) {
            textfieldEffectView?.tintColor = theme.colors.midBackground
            nextPrevButtonEffectView?.tintColor = theme.colors.midBackground
            modernMagnifyImageView.tintColor = theme.colors.primaryText
            modernFindClearButton.tintColor = theme.colors.secondaryText
            modernCurrentMatchLabel.textColor = theme.colors.secondaryText
            modernCloseButton.tintColor = theme.colors.link
            modernNextButton?.tintColor = theme.colors.secondaryText
            modernPrevButton?.tintColor = theme.colors.secondaryText
        } else {
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
}

// MARK: Private

private extension FindAndReplaceKeyboardBar {
    
    func setupStaticAccessibilityLabels() {
        let findTextFieldLabel = WMFLocalizedString("find-textfield-accessibility", value: "Find", comment: "Accessibility label for the find text field.")
        let clearButtonLabel = WMFLocalizedString("find-clear-button-accessibility", value: "Clear find", comment: "Accessibility label for the clear values X button in the find textfield.")
        let nextButtonLabel = WMFLocalizedString("find-next-button-accessibility", value: "Next find result", comment: "Accessibility label for the next button when traversing find results.")
        let prevButtonLabel = WMFLocalizedString("find-previous-button-accessibility", value: "Previous find result", comment: "Accessibility label for the previous button when traversing find results.")
        if #available(iOS 26.0, *) {
            modernFindTextField.accessibilityLabel = findTextFieldLabel
            modernFindClearButton.accessibilityLabel = clearButtonLabel
            modernCloseButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
            modernNextButton?.accessibilityLabel = nextButtonLabel
            modernPrevButton?.accessibilityLabel = prevButtonLabel
        } else {
            legacyFindTextField.accessibilityLabel = findTextFieldLabel
            legacyFindClearButton.accessibilityLabel = clearButtonLabel
            legacyCloseButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
            legacyNextButton.accessibilityLabel = nextButtonLabel
            legacyPreviousButton.accessibilityLabel = prevButtonLabel
        }

    }
    
    func hideUndoRedoIcons() {
        if #available(iOS 26.0, *) {
            if modernFindTextField.responds(to: #selector(getter: inputAssistantItem)) {
                modernFindTextField.inputAssistantItem.leadingBarButtonGroups = []
                modernFindTextField.inputAssistantItem.trailingBarButtonGroups = []
            }
        } else {
            if legacyFindTextField.responds(to: #selector(getter: inputAssistantItem)) {
                legacyFindTextField.inputAssistantItem.leadingBarButtonGroups = []
                legacyFindTextField.inputAssistantItem.trailingBarButtonGroups = []
            }
        }
        
    }
    
    func updateMatchPlacement(index: Int, total: UInt) {
        if #available(iOS 26.0, *) {
            guard let findText = modernFindTextField.text,
                findText.count > 0 else {
                    modernCurrentMatchLabel.text = nil
                    return
            }
            

        } else {
            guard let findText = legacyFindTextField.text,
                findText.count > 0 else {
                    legacyCurrentMatchLabel.text = nil
                    return
            }
        }

        if total > 0 && index == -1 {
            matchPlacement = FindMatchPlacement(index: nil, total: total)
        } else {
            matchPlacement = FindMatchPlacement(index: UInt(max(0, index + 1)), total: total)
        }
    }
    
    func updatePreviousNextButtonsState(total: UInt) {
        if #available(iOS 26.0, *) {
            modernPrevButton?.isEnabled = total >= 2
            modernNextButton?.isEnabled = total >= 2
        } else {
            legacyPreviousButton.isEnabled = total >= 2
            legacyNextButton.isEnabled = total >= 2
        }

    }
}
