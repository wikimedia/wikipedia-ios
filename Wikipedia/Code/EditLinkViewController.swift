import UIKit

protocol EditLinkViewControllerDelegate: AnyObject {
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didTapCloseButton button: UIBarButtonItem)
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFinishEditingLink displayText: String?, linkTarget: String)
    func editLinkViewControllerDidRemoveLink(_ editLinkViewController: EditLinkViewController)
}

class EditLinkViewController: UIInputViewController {
    weak var delegate: EditLinkViewControllerDelegate?
    private var theme = Theme.standard

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var displayTextLabel: UILabel!
    @IBOutlet private weak var displayTextView: UITextView!
    @IBOutlet private weak var linkTargetLabel: UILabel!
    @IBOutlet private weak var linkTargetContainerView: UIView!
    @IBOutlet private weak var removeLinkButton: UIButton!
    @IBOutlet private var separatorViews: [UIView] = []

    private lazy var closeButton: UIBarButtonItem = {
        let closeButton = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(close(_:)))
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return closeButton
    }()

    private lazy var doneButton: UIBarButtonItem = {
        // move "Done" to CommonStrings
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(finishEditing(_:)))
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return closeButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit link"
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = doneButton
        apply(theme: theme)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        displayTextLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        linkTargetLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        displayTextView.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        removeLinkButton.titleLabel?.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }

    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.editLinkViewController(self, didTapCloseButton: sender)
    }

    @objc private func finishEditing(_ sender: UIBarButtonItem) {
        let displayText = displayTextView.text
        // get link target from article cell
        let linkTarget = "TEST"
        delegate?.editLinkViewController(self, didFinishEditingLink: displayText, linkTarget: linkTarget)
    }

    @IBAction private func removeLink(_ sender: UIButton) {
        delegate?.editLinkViewControllerDidRemoveLink(self)
    }
}

extension EditLinkViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        contentView.backgroundColor = theme.colors.paperBackground
        view.backgroundColor = theme.colors.baseBackground
        separatorViews.forEach { $0.backgroundColor = theme.colors.border }
        displayTextLabel.textColor = theme.colors.secondaryText
        linkTargetLabel.textColor = theme.colors.secondaryText
        removeLinkButton.tintColor = theme.colors.destructive
        removeLinkButton.backgroundColor = theme.colors.paperBackground
        closeButton.tintColor = theme.colors.primaryText
        doneButton.tintColor = theme.colors.link
        displayTextView.textColor = theme.colors.primaryText
    }
}
