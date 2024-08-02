import UIKit

protocol WMFFindAndReplaceViewDelegate: AnyObject {
    func findAndReplaceView(_ view: WMFFindAndReplaceView, didChangeFindText text: String)
    func findAndReplaceView(_ view: WMFFindAndReplaceView, didTapReplaceSingle replaceText: String)
    func findAndReplaceView(_ view: WMFFindAndReplaceView, didTapReplaceAll replaceText: String)
    func findAndReplaceViewDidTapNext(_ view: WMFFindAndReplaceView)
    func findAndReplaceViewDidTapPrevious(_ view: WMFFindAndReplaceView)
}

class WMFFindAndReplaceView: WMFComponentView {
    
    // MARK: - Nested
    
    enum ReplaceType {
        case single
        case all
    }
    
    // MARK: - IBOutlet Properties

    @IBOutlet private weak var outerContainer: UIView!
    @IBOutlet private var outerStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var outerStackViewTrailingConstraint: NSLayoutConstraint!
    
    // Find outlets
    @IBOutlet private var findStackView: UIStackView!
    @IBOutlet private var nextPrevButtonStackView: UIStackView!
    @IBOutlet private(set) var findTextField: UITextField!
    @IBOutlet private var currentMatchInfoLabel: UILabel!
    @IBOutlet private var findClearButton: UIButton!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var previousButton: UIButton!
    @IBOutlet private var magnifyImageView: UIImageView!
    @IBOutlet weak var findTextfieldContainer: UIView!
    
    // Replace outlets
    @IBOutlet private var replaceStackView: UIStackView!
    @IBOutlet private var replaceTextField: UITextField!
    @IBOutlet private var replaceTypeLabel: UILabel!
    @IBOutlet private var replacePlaceholderLabel: UILabel!
    @IBOutlet private var replaceClearButton: UIButton!
    @IBOutlet private var replaceButton: UIButton!
    @IBOutlet private var replaceSwitchButton: UIButton!
    @IBOutlet private var pencilImageView: UIImageView!
    @IBOutlet private weak var replaceTextfieldContainer: UIView!
    
    weak var delegate: WMFFindAndReplaceViewDelegate?
    var viewModel: WMFFindAndReplaceViewModel?
    private var replaceType: ReplaceType = .single
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        maximumContentSizeCategory = .accessibilityLarge

        closeButton.setImage(WMFSFSymbolIcon.for(symbol: .close), for: .normal)
        closeButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.findCloseButtonAccessibility
        previousButton.setImage(WMFSFSymbolIcon.for(symbol: .chevronUp), for: .normal)
        previousButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.findPreviousButtonAccessibility
        previousButton.imageView?.contentMode = .center
        nextButton.setImage(WMFSFSymbolIcon.for(symbol: .chevronDown), for: .normal)
        nextButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.findNextButtonAccessibility
        nextButton.imageView?.contentMode = .center

        replaceButton.setImage(WMFIcon.replace, for: .normal)
        replaceButton.accessibilityLabel = String.localizedStringWithFormat(WMFSourceEditorLocalizedStrings.current.replaceButtonAccessibilityFormat, WMFSourceEditorLocalizedStrings.current.replaceTypeSingleAccessibility)
        
        replaceButton.imageView?.contentMode = .center
        replaceSwitchButton.setImage(WMFSFSymbolIcon.for(symbol: .ellipsis), for: .normal)
        replaceSwitchButton.accessibilityLabel = String.localizedStringWithFormat(WMFSourceEditorLocalizedStrings.current.replaceTypeButtonAccessibilityFormat, WMFSourceEditorLocalizedStrings.current.replaceTypeSingleAccessibility)
        replaceSwitchButton.imageView?.contentMode = .center
        
        replaceSwitchButton.showsMenuAsPrimaryAction = true
        replaceSwitchButton.menu = replaceSwitchButtonMenu()

        magnifyImageView.image = WMFSFSymbolIcon.for(symbol: .magnifyingGlass)
        magnifyImageView.contentMode = .center
        pencilImageView.image = WMFIcon.pencil
        pencilImageView.contentMode = .center
        
        findClearButton.setImage(WMFSFSymbolIcon.for(symbol: .multiplyCircleFill), for: .normal)
        findClearButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.findClearButtonAccessibility
        findClearButton.imageView?.contentMode = .center
        replaceClearButton.setImage(WMFSFSymbolIcon.for(symbol: .multiplyCircleFill), for: .normal)
        replaceClearButton.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.replaceClearButtonAccessibility
        replaceClearButton.imageView?.contentMode = .center

        findTextField.adjustsFontForContentSizeCategory = true
        findTextField.font = WMFFont.for(.caption1, compatibleWith: appEnvironment.traitCollection)
        findTextField.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.findTextFieldAccessibility
        findTextField.autocorrectionType = .yes
        findTextField.spellCheckingType = .yes
        findTextField.delegate = self

        replaceTextField.adjustsFontForContentSizeCategory = true
        replaceTextField.font = WMFFont.for(.caption1, compatibleWith: appEnvironment.traitCollection)
        replaceTextField.accessibilityLabel = WMFSourceEditorLocalizedStrings.current.replaceTextFieldAccessibility
        replaceTextField.autocorrectionType = .yes
        replaceTextField.spellCheckingType = .yes
        replaceTextField.delegate = self

        currentMatchInfoLabel.adjustsFontForContentSizeCategory = true
        currentMatchInfoLabel.font = WMFFont.for(.caption1, compatibleWith: appEnvironment.traitCollection)

        replaceTypeLabel.adjustsFontForContentSizeCategory = true
        replaceTypeLabel.font = WMFFont.for(.caption1, compatibleWith: appEnvironment.traitCollection)
        replaceTypeLabel.text = WMFSourceEditorLocalizedStrings.current.replaceTypeSingle
        replaceTypeLabel.isAccessibilityElement = false

        replacePlaceholderLabel.adjustsFontForContentSizeCategory = true
        replacePlaceholderLabel.font = WMFFont.for(.caption1, compatibleWith: appEnvironment.traitCollection)
        replacePlaceholderLabel.text = WMFSourceEditorLocalizedStrings.current.replaceTextfieldPlaceholder
        replacePlaceholderLabel.isAccessibilityElement = false

        updateColors()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 46)
    }
    
    // MARK: - Internal
    
    func update(viewModel: WMFFindAndReplaceViewModel) {
        self.viewModel = viewModel
        
        updateConfiguration(configuration: viewModel.configuration)
        
        let findIsEmpty = (findTextField.text ?? "").isEmpty
        if let currentMatchInfo = viewModel.currentMatchInfo,
           !findIsEmpty {
            currentMatchInfoLabel.text = "\(currentMatchInfo)"
        } else {
            currentMatchInfoLabel.text = nil
        }

        if let currentMatchInfoAccessibility = viewModel.currentMatchInfoAccessibility {
            currentMatchInfoLabel.accessibilityLabel = currentMatchInfoAccessibility
        } else {
            currentMatchInfoLabel.accessibilityLabel = currentMatchInfoLabel.text
        }
        
        nextButton.isEnabled = viewModel.nextPrevButtonsAreEnabled
        previousButton.isEnabled = viewModel.nextPrevButtonsAreEnabled
        
        let replaceTextCount = replaceTextField.text?.count ?? 0
        replaceButton.isEnabled = replaceTextCount > 0 && viewModel.matchCount > 0 && replaceTextField.text != findTextField.text
        
        switch (replaceTextField.isFirstResponder, replaceTextCount) {
        case (false, 0):
            replaceTypeLabel.isHidden = true
            replacePlaceholderLabel.isHidden = false
        case (true, 0):
            replaceTypeLabel.isHidden = true
            replacePlaceholderLabel.isHidden = true
        case (_, 1...):
            replaceTypeLabel.isHidden = false
            replacePlaceholderLabel.isHidden = true
        default:
            break
        }
    }
    
    func clearFind() {
        findTextField.text = ""
    }
    
    func resetReplace() {
        replaceTextField.text = ""
        replaceTypeLabel.isHidden = true
        replacePlaceholderLabel.isHidden = false
    }
    
    // MARK: - Overrides
    
    override func appEnvironmentDidChange() {
        
        // Confirm IBOutlets are populated first
        guard findTextField != nil else {
            return
        }
        
        updateColors()
    }

    // MARK: Public

      func focus() {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
              self.findTextField.becomeFirstResponder()
          }
      }

    // MARK: - Button Actions
    
    @IBAction private func tappedFindClear() {
        findTextField.text = ""
        debouncedFindTextfieldDidChange()
    }
    
    @IBAction private func tappedReplaceClear() {
        replaceTextField.text = ""
        if let viewModel {
            update(viewModel: viewModel)
        }
    }
    
    @IBAction private func tappedClose() {
    }
    
    @IBAction private func tappedNext() {
        delegate?.findAndReplaceViewDidTapNext(self)
    }
    
    @IBAction private func tappedPrevious() {
        delegate?.findAndReplaceViewDidTapPrevious(self)
    }
    
    @IBAction private func tappedReplace() {
        guard let replaceText = replaceTextField.text,
          !replaceText.isEmpty else {
              return
          }
        
        switch replaceType {
        case .single:
            delegate?.findAndReplaceView(self, didTapReplaceSingle: replaceText)
        case .all:
            delegate?.findAndReplaceView(self, didTapReplaceAll: replaceText)
        }
        
    }
    
    // MARK: - Private Helpers
    
    private func updateConfiguration(configuration: WMFFindAndReplaceViewModel.Configuration) {
        switch configuration {
        case .findOnly:
            replaceStackView.isHidden = true
            closeButton.isHidden = false
            findStackView.insertArrangedSubview(nextPrevButtonStackView, at: 0)
            outerStackViewLeadingConstraint.constant = 10
            outerStackViewTrailingConstraint.constant = 5
            accessibilityElements = [previousButton, nextButton, findTextField, currentMatchInfoLabel, findClearButton, closeButton].compactMap { $0 as Any }
        case .findAndReplace:
            replaceStackView.isHidden = false
            closeButton.isHidden = true
            findStackView.addArrangedSubview(nextPrevButtonStackView)
            outerStackViewLeadingConstraint.constant = 18
            outerStackViewTrailingConstraint.constant = 18
            accessibilityElements = [findTextField, currentMatchInfoLabel, findClearButton, previousButton, nextButton, replaceTextField, replaceClearButton, replaceButton, replaceSwitchButton].compactMap { $0 as Any }
        }
    }
    
    private func updateColors() {
        let theme = WMFAppEnvironment.current.theme
        
        backgroundColor = UIColor.systemGray4
        
        findTextField.keyboardAppearance = theme.keyboardAppearance
        findTextfieldContainer.backgroundColor = theme.keyboardBarSearchFieldBackground
        findTextField.textColor = theme.text
        closeButton.tintColor = theme.inputAccessoryButtonTint
        previousButton.tintColor = theme.inputAccessoryButtonTint
        nextButton.tintColor = theme.inputAccessoryButtonTint
        magnifyImageView.tintColor = theme.inputAccessoryButtonTint
        findClearButton.tintColor = theme.inputAccessoryButtonTint
        currentMatchInfoLabel.textColor = theme.secondaryText
        
        replaceTextField.keyboardAppearance = theme.keyboardAppearance
        replaceTextfieldContainer.backgroundColor = theme.keyboardBarSearchFieldBackground
        replaceTextField.textColor = theme.text
        replaceButton.tintColor = theme.inputAccessoryButtonTint
        replaceSwitchButton.tintColor = theme.inputAccessoryButtonTint
        pencilImageView.tintColor = theme.inputAccessoryButtonTint
        replaceClearButton.tintColor = theme.inputAccessoryButtonTint
        replaceTypeLabel.textColor = theme.secondaryText
        replacePlaceholderLabel.textColor = theme.secondaryText
    }
    
    @objc private func debouncedFindTextfieldDidChange() {

        guard let text = findTextField.text else {
            return
        }

        delegate?.findAndReplaceView(self, didChangeFindText: text)
    }
    
    private func replaceSwitchButtonMenu() -> UIMenu {
        let replace = UIAction(title: WMFSourceEditorLocalizedStrings.current.replaceTypeSingle) { [weak self] _ in
            self?.replaceType = .single
            self?.replaceTypeLabel.text = WMFSourceEditorLocalizedStrings.current.replaceTypeSingle
            
            self?.replaceButton.accessibilityLabel = String.localizedStringWithFormat(WMFSourceEditorLocalizedStrings.current.replaceButtonAccessibilityFormat, WMFSourceEditorLocalizedStrings.current.replaceTypeSingleAccessibility)
            
            self?.replaceSwitchButton.accessibilityLabel = String.localizedStringWithFormat(WMFSourceEditorLocalizedStrings.current.replaceTypeButtonAccessibilityFormat, WMFSourceEditorLocalizedStrings.current.replaceTypeSingleAccessibility)
        }
        
        let replaceAll = UIAction(title: WMFSourceEditorLocalizedStrings.current.replaceTypeAll) { [weak self] _ in
            self?.replaceType = .all
            self?.replaceTypeLabel.text = WMFSourceEditorLocalizedStrings.current.replaceTypeAll
            
            self?.replaceButton.accessibilityLabel = String.localizedStringWithFormat(WMFSourceEditorLocalizedStrings.current.replaceButtonAccessibilityFormat, WMFSourceEditorLocalizedStrings.current.replaceTypeAll)
            
            self?.replaceSwitchButton.accessibilityLabel = String.localizedStringWithFormat(WMFSourceEditorLocalizedStrings.current.replaceTypeButtonAccessibilityFormat, WMFSourceEditorLocalizedStrings.current.replaceTypeAllAccessibility)
        }
       
        return UIMenu(title: WMFSourceEditorLocalizedStrings.current.findAndReplaceTitle, children: [replace, replaceAll])
    }
}

extension WMFFindAndReplaceView: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == self.findTextField {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(debouncedFindTextfieldDidChange), object: nil)
            perform(#selector(debouncedFindTextfieldDidChange), with: nil, afterDelay: 0.5)
        } else if textField == self.replaceTextField {
            if let viewModel {
                update(viewModel: viewModel)
            }
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let viewModel {
            update(viewModel: viewModel)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == findTextField {
            debouncedFindTextfieldDidChange()
        } else if textField == replaceTextField {
            tappedReplace()
        }

        return true
    }
}
