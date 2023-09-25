import UIKit

class WKFindAndReplaceView: WKComponentView {
    
    // MARK: - IBOutlet Properties

    @IBOutlet private weak var outerContainer: UIView!
    @IBOutlet private var outerStackViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var outerStackViewTrailingConstraint: NSLayoutConstraint!
    
    // Find outlets
    @IBOutlet private var findStackView: UIStackView!
    @IBOutlet private var nextPrevButtonStackView: UIStackView!
    @IBOutlet private var findTextField: UITextField!
    @IBOutlet private var currentMatchLabel: UILabel!
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
    
    private var viewModel: WKFindAndReplaceViewModel?
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        closeButton.setImage(WKIcon.close, for: .normal)
        previousButton.setImage(WKIcon.chevronUp, for: .normal)
        nextButton.setImage(WKIcon.chevronDown, for: .normal)
        
        replaceButton.setImage(WKIcon.replace, for: .normal)
        replaceSwitchButton.setImage(WKIcon.more, for: .normal)
        
        magnifyImageView.image = WKIcon.find
        pencilImageView.image = WKIcon.pencil
        
        findClearButton.setImage(WKIcon.closeCircle, for: .normal)
        replaceClearButton.setImage(WKIcon.closeCircle, for: .normal)
        
        findTextField.adjustsFontForContentSizeCategory = true
        findTextField.font = WKFont.for(.caption1, compatibleWith: appEnvironment.traitCollection)
                                        
        replaceTextField.adjustsFontForContentSizeCategory = true
        replaceTextField.font = WKFont.for(.caption1, compatibleWith: appEnvironment.traitCollection)
        
        currentMatchLabel.adjustsFontForContentSizeCategory = true
        currentMatchLabel.font = WKFont.for(.caption1, compatibleWith: appEnvironment.traitCollection)
        currentMatchLabel.text = "1 / 10"
        
        replaceTypeLabel.adjustsFontForContentSizeCategory = true
        replaceTypeLabel.font = WKFont.for(.caption1, compatibleWith: appEnvironment.traitCollection)
        replaceTypeLabel.text = "Replace"

        replacePlaceholderLabel.adjustsFontForContentSizeCategory = true
        replacePlaceholderLabel.font = WKFont.for(.caption1, compatibleWith: appEnvironment.traitCollection)
        replacePlaceholderLabel.text = "Replace with..."
                                        
        updateColors()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 46)
    }
    
    // MARK: - Internal
    
    func configure(viewModel: WKFindAndReplaceViewModel) {
        self.viewModel = viewModel
        
        updateConfiguration(configuration: viewModel.configuration)
    }
    
    // MARK: - Overrides
    
    override func appEnvironmentDidChange() {
        
        // Confirm IBOutlets are populated first
        guard findTextField != nil else {
            return
        }
        
        updateColors()
    }
    
    // MARK: - Button Actions
    
    @IBAction private func tappedFindClear() {
    }
    
    @IBAction private func tappedReplaceClear() {
    }
    
    @IBAction private func tappedClose() {
    }
    
    @IBAction private func tappedNext() {
    }
    
    @IBAction private func tappedPrevious() {
    }
    
    @IBAction private func tappedReplace() {
    }
    
    @IBAction private func tappedReplaceSwitch() {
    }
    
    @IBAction private func textFieldDidChange(_ sender: UITextField) {
    }
    
    // MARK: - Private Helpers
    
    private func updateConfiguration(configuration: WKFindAndReplaceViewModel.Configuration) {
        switch configuration {
        case .findOnly:
            replaceStackView.isHidden = true
            closeButton.isHidden = false
            findStackView.insertArrangedSubview(nextPrevButtonStackView, at: 0)
            outerStackViewLeadingConstraint.constant = 10
            outerStackViewTrailingConstraint.constant = 5
        case .findAndReplace:
            replaceStackView.isHidden = false
            closeButton.isHidden = true
            findStackView.addArrangedSubview(nextPrevButtonStackView)
            outerStackViewLeadingConstraint.constant = 18
            outerStackViewTrailingConstraint.constant = 18
        }
    }
    
    private func updateColors() {
        let theme = WKAppEnvironment.current.theme
        
        backgroundColor = UIColor.systemGray4
        
        findTextField.keyboardAppearance = theme.keyboardAppearance
        findTextfieldContainer.backgroundColor = theme.keyboardBarSearchFieldBackground
        findTextField.textColor = theme.text
        closeButton.tintColor = theme.inputAccessoryButtonTint
        previousButton.tintColor = theme.inputAccessoryButtonTint
        nextButton.tintColor = theme.inputAccessoryButtonTint
        magnifyImageView.tintColor = theme.inputAccessoryButtonTint
        findClearButton.tintColor = theme.inputAccessoryButtonTint
        currentMatchLabel.textColor = theme.secondaryText
        
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
}
