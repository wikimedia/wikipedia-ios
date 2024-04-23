import UIKit
import WMF

protocol EditSummaryViewDelegate: AnyObject {
    func summaryChanged(newSummary: String)
    func learnMoreButtonTapped(sender: UIButton)
}

enum EditSummaryViewCannedButtonType {
    case typo, grammar, link, addedImage, addedImageAndCaption
    
    func buttonTitle(for languageCode: String) -> String {
        switch self {
        case .typo:
            return WMFLocalizedString("edit-summary-choice-fixed-typos", languageCode: languageCode, value: "Fixed typo", comment: "Button text for quick 'fixed typos' edit summary selection")
        case .grammar:
            return WMFLocalizedString("edit-summary-choice-fixed-grammar", languageCode: languageCode, value: "Fixed grammar", comment: "Button text for quick 'improved grammar' edit summary selection")
        case .link:
            return WMFLocalizedString("edit-summary-choice-linked-words", languageCode: languageCode, value: "Added links", comment: "Button text for quick 'link addition' edit summary selection")
        case .addedImage:
            return WMFLocalizedString("edit-summary-choice-added-image", languageCode: languageCode, value: "Added image", comment: "Button text for quick 'added image' edit summary selection")
        case .addedImageAndCaption:
            return WMFLocalizedString("edit-summary-choice-added-image-and-caption", languageCode: languageCode, value: "Added image and caption", comment: "Button text for quick 'added image and caption' edit summary selection")
        }
    }
}

class EditSummaryViewController: UIViewController, Themeable {
    static let maximumSummaryLength = 255
    
    public var theme: Theme = .standard

    public var languageCode: String = "en"
    public var cannedSummaryTypes: [EditSummaryViewCannedButtonType] = [.typo, .grammar, .link]

    public weak var delegate: EditSummaryViewDelegate?
    
    @IBOutlet private weak var addSummaryLabel: UILabel!
    @IBOutlet private weak var learnMoreButton: UIButton!
    @IBOutlet private weak var summaryTextField: ThemeableTextField!

    @IBOutlet private weak var fixedTypoButton: UIButton!
    @IBOutlet private weak var fixedGrammarButton: UIButton!
    @IBOutlet private weak var addedLinksButton: UIButton!
    @IBOutlet private var cannedEditSummaryButtons: [UIButton]!

    private(set) var semanticContentAttribute: UISemanticContentAttribute?

    override func viewDidLoad() {
        super.viewDidLoad()

        let placeholderText = WMFLocalizedString("edit-summary-placeholder-text", languageCode: languageCode, value: "How did you improve the article?", comment: "Placeholder text which appears initially in the free-form edit summary text box")

        cannedEditSummaryButtons.compactMap { $0.titleLabel }.forEach {
            $0.numberOfLines = 1
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        addSummaryLabel.text = WMFLocalizedString("edit-summary-add-summary-text", languageCode: languageCode, value: "Add an edit summary", comment: "Text for add summary label")
        learnMoreButton.setTitle(CommonStrings.learnMoreTitle(languageCode: languageCode), for: .normal)
        summaryTextField.placeholder = placeholderText
        summaryTextField.delegate = self
        summaryTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        
        updateCannedSummaryButtons()
        setupSemanticContentAttibute()
        apply(theme: theme)
    }

    func setupSemanticContentAttibute() {
        let semanticContentAttibute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: languageCode)
        
        addSummaryLabel.semanticContentAttribute = semanticContentAttibute
        learnMoreButton.semanticContentAttribute = semanticContentAttibute

        summaryTextField.semanticContentAttribute = semanticContentAttibute
        summaryTextField.textAlignment = semanticContentAttibute == .forceRightToLeft ? .right : .left
    }

    @IBAction private func learnMoreButtonTapped(sender: UIButton) {
        delegate?.learnMoreButtonTapped(sender: sender)
    }

    @objc public func textFieldDidChange(textField: UITextField) {
        notifyDelegateOfSummaryChange()
    }

    private func notifyDelegateOfSummaryChange() {
        delegate?.summaryChanged(newSummary: summaryTextField.text ?? "")
    }

    @IBAction private func cannedSummaryButtonTapped(sender: UIButton) {
        guard let senderLabel = sender.titleLabel?.text else {
            assertionFailure("Expected button information not found")
            return
        }
        updateInputText(to: senderLabel)
    }

    func updateInputText(to text: String) {
        summaryTextField.text = text
        notifyDelegateOfSummaryChange()
    }

    public func setLanguage(for pageURL: URL?) {
        if let languageCode = pageURL?.wmf_languageCode {
            self.languageCode = languageCode
        }
    }


    public func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        addSummaryLabel.textColor = theme.colors.secondaryText
        learnMoreButton.titleLabel?.textColor = theme.colors.link
        summaryTextField.apply(theme: theme)
        cannedEditSummaryButtons.forEach {
            $0.setTitleColor(theme.colors.tagText, for: .normal)
            $0.backgroundColor = theme.colors.tagBackground
        }
    }
    
    private func updateCannedSummaryButtons() {
        
        guard cannedSummaryTypes.count <= cannedEditSummaryButtons.count else {
            assertionFailure("We must have equal to or more cannedEditSummaryButtons connected than cannedSummaryTypes configured. Please update via interface builder and connect additional buttons")
            return
        }
        
        for (index, button) in cannedEditSummaryButtons.enumerated() {
            
            if index >= cannedSummaryTypes.count {
                button.isHidden = true
                continue
            }
            
            let type = cannedSummaryTypes[index]
            button.setTitle(type.buttonTitle(for: languageCode), for: .normal)
            button.isHidden = false
        }
    }
}

extension EditSummaryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // save()
        return true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newLength = (textField.text?.count ?? 0) + string.count - range.length
        return newLength <= EditSummaryViewController.maximumSummaryLength
    }
}

public class SummaryButtonScrollView: UIScrollView {
    @IBOutlet private var cannedEditSummaryButtons: [UIButton]!
    private func sizeEncompassingTallestButton() -> CGSize {
        let heightOfTallestButton = cannedEditSummaryButtons.map { $0.intrinsicContentSize.height }.max()
        return CGSize(width: UIView.noIntrinsicMetric, height: heightOfTallestButton ?? UIView.noIntrinsicMetric)
    }
    override public var intrinsicContentSize: CGSize {
        return sizeEncompassingTallestButton()
    }
}
