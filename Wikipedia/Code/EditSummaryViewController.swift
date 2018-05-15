import UIKit
import WMF

enum EditSummaryViewControllerConstants {
    static let maximumSummaryLength = 255
}

class EditSummaryViewController: UIViewController {
    
    typealias C = EditSummaryViewControllerConstants
    
    @objc var didSaveSummary: ((String?) -> ())?
    @objc var summaryText: String = ""
    
    fileprivate var theme: Theme = Theme.standard
    @IBOutlet private weak var bottomLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var summaryTextField: ThemeableTextField! {
        didSet {
            summaryTextField.placeholder = WMFLocalizedStringWithDefaultValue("edit-summary-field-placeholder-text", nil, nil, "Other ways you improved the article", "Placeholder text which appears initially in the free-form edit summary text box")
            summaryTextField.returnKeyType = .done
            summaryTextField.delegate = self
            summaryTextField.textAlignment = .natural
            summaryTextField.font = UIFont.systemFont(ofSize: 14.0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(closeButtonPressed))
        let localization = WMFLocalizedStringWithDefaultValue("button-done", nil, nil, "Done", "Button text for done button used in various places.\n{{Identical|Done}}")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: localization, style: .plain, target: self, action: #selector(save))
        
        bottomLineHeightConstraint.constant = 1.0 / UIScreen.main.scale
        
        apply(theme: theme)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        summaryTextField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        summaryTextField.text = summaryText
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        summaryTextField.resignFirstResponder()
    }
    
    @objc func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func save() {
        let trimmedSummary = summaryTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        didSaveSummary?(trimmedSummary)
        dismiss(animated: true, completion: nil)
    }
}

extension EditSummaryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        save()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newLength = (textField.text?.count ?? 0) + string.count - range.length
        return newLength <= C.maximumSummaryLength
    }
}

extension EditSummaryViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else { return }
        view.backgroundColor = theme.colors.paperBackground
        summaryTextField.apply(theme: theme)
    }
}
