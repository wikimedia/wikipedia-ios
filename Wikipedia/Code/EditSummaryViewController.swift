
import UIKit

protocol EditSummaryViewDelegate: AnyObject {
    func summaryChanged(newSummary: String)
    func learnMoreButtonTapped(sender: UIButton)
    func cannedButtonTapped(type: EditSummaryViewCannedButtonType)
}

// Int because we use `tag` from storyboard buttons.
public enum EditSummaryViewCannedButtonType: Int {
    case typo, grammar, link
    
    var eventLoggingKey: String {
        switch self {
        case .typo:
            return "typo"
        case .grammar:
            return "grammar"
        case .link:
            return "links"
        }
    }
}

class EditSummaryViewController: UIViewController, Themeable {
    static let maximumSummaryLength = 255
    
    public var theme: Theme = .standard

    public weak var delegate: EditSummaryViewDelegate?
    
    @IBOutlet private weak var addSummaryLabel: UILabel!
    @IBOutlet private weak var learnMoreButton: UIButton!
    @IBOutlet private weak var summaryTextField: ThemeableTextField!

    @IBOutlet private weak var fixedTypoButton: UIButton!
    @IBOutlet private weak var fixedGrammarButton: UIButton!
    @IBOutlet private weak var addedLinksButton: UIButton!
    @IBOutlet private var cannedEditSummaryButtons: [UIButton]!

    private let placeholderText = WMFLocalizedString("edit-summary-placeholder-text", value: "How did you improve the article?", comment: "Placeholder text which appears initially in the free-form edit summary text box")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cannedEditSummaryButtons.compactMap{ $0.titleLabel }.forEach {
            $0.numberOfLines = 1
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        addSummaryLabel.text = WMFLocalizedString("edit-summary-add-summary-text", value: "Add an edit summary", comment: "Text for add summary label")
        learnMoreButton.setTitle(WMFLocalizedString("edit-summary-learn-more-text", value: "Learn more", comment: "Text for learn more button"), for: .normal)
        summaryTextField.placeholder = placeholderText
        summaryTextField.delegate = self
        summaryTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
        fixedTypoButton.setTitle(WMFLocalizedString("edit-summary-choice-fixed-typos", value: "Fixed typo", comment: "Button text for quick 'fixed typos' edit summary selection"), for: .normal)
        fixedGrammarButton.setTitle(WMFLocalizedString("edit-summary-choice-fixed-grammar", value: "Fixed grammar", comment: "Button text for quick 'improved grammar' edit summary selection"), for: .normal)
        addedLinksButton.setTitle(WMFLocalizedString("edit-summary-choice-linked-words", value: "Added links", comment: "Button text for quick 'link addition' edit summary selection"), for: .normal)
        
        apply(theme: theme)
    }
        
    @IBAction private func learnMoreButtonTapped(sender: UIButton) {
        delegate?.learnMoreButtonTapped(sender: sender)
    }

    @objc public func textFieldDidChange(textField: UITextField){
        notifyDelegateOfSummaryChange()
    }

    private func notifyDelegateOfSummaryChange() {
        delegate?.summaryChanged(newSummary: summaryTextField.text ?? "")
    }

    @IBAction private func cannedSummaryButtonTapped(sender: UIButton) {
        summaryTextField.text = sender.titleLabel?.text
        notifyDelegateOfSummaryChange()
        guard let buttonType = EditSummaryViewCannedButtonType(rawValue: sender.tag) else {
            assertionFailure("Expected button type not found")
            return
        }
        delegate?.cannedButtonTapped(type: buttonType)
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
}

extension EditSummaryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //save()
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
        let heightOfTallestButton = cannedEditSummaryButtons.map{ $0.intrinsicContentSize.height }.max()
        return CGSize(width: UIView.noIntrinsicMetric, height: heightOfTallestButton ?? UIView.noIntrinsicMetric)
    }
    override public var intrinsicContentSize: CGSize {
        return sizeEncompassingTallestButton()
    }
}
