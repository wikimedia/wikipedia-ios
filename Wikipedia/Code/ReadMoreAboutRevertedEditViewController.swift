import UIKit
import WMF

@objc protocol ReadMoreAboutRevertedEditViewControllerDelegate: class {
    func readMoreAboutRevertedEditViewControllerDidPressGoToArticleButton(_ articleURL: URL)
}

class ReadMoreAboutRevertedEditViewController: WMFScrollViewController {
    private var theme = Theme.standard
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var contentTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var button: UIButton!

    @objc public var articleURL: URL?

    @objc public weak var delegate: ReadMoreAboutRevertedEditViewControllerDelegate?

    override public func viewDidLoad() {
        super.viewDidLoad()

        contentTextView.delegate = self

        title = CommonStrings.revertedEditTitle
        titleLabel.text = WMFLocalizedString("reverted-edit-thanks-for-editing-title", value: "Thanks for editing Wikipedia!", comment: "Title thanking the user for contributing to Wikipedia")
        subtitleLabel.text = WMFLocalizedString("reverted-edit-possible-reasons-subtitle", value: "We know that you tried your best, but one of the reviewers had a concern.\n\nPossible reasons your edit was reverted include:", comment: "Subtitle leading to an explanation why an edit was reverted.")
        button.setTitle(WMFLocalizedString("reverted-edit-back-to-article-button-title", value: "Back to article", comment: "Title for button that allows the user to go back to the article they edited"), for: .normal)

        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)

        updateFonts()
        view.wmf_configureSubviewsForDynamicType()

        apply(theme: theme)
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func buttonPressed() {
        close()
        guard let articleURL = articleURL else {
            assertionFailure("articleURL should be set by now")
            return
        }
        guard let delegate = delegate else {
            assertionFailure("delegate should be set by now")
            return
        }
        delegate.readMoreAboutRevertedEditViewControllerDidPressGoToArticleButton(articleURL)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let closeButton = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem = closeButton
    }

    let editingGuidelines = (text: WMFLocalizedString("reverted-edit-view-guidelines-text", value: "View guidelines", comment: "Text for link for viewing editing guidelines"),
                             urlString: "https://www.wikidata.org/wiki/Help:FAQ#Editing")

    private var contentTextViewText: NSAttributedString? {
        let formatString = WMFLocalizedString("reverted-edit-possible-reasons", value: "- Your contribution didn’t follow one of the guidelines. %1$@ \n\n - Your contribution looked like an experiment or vandalism", comment: "List of possible reasons describing why an edit might have been reverted. %1$@ is replaced with a link to view editing guidelines")
        let baseAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection), .foregroundColor: theme.colors.primaryText];
        let linkAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: theme.colors.link,
        .font: UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)]
        guard let attributedString = formatString.attributedString(attributes: baseAttributes, substitutionStrings: [editingGuidelines.text], substitutionAttributes: [linkAttributes]) else {
            return nil
        }
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        let range = mutableAttributedString.mutableString.range(of: editingGuidelines.text)
        mutableAttributedString.addAttribute(NSAttributedString.Key.link, value: editingGuidelines.urlString, range: range)

        return mutableAttributedString
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        titleLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        subtitleLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        contentTextView.attributedText = contentTextViewText
        button.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentTextViewHeightConstraint.constant = contentTextView.sizeThatFits(contentTextView.frame.size).height
    }
}

extension ReadMoreAboutRevertedEditViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        contentTextView.backgroundColor = view.backgroundColor
        titleLabel.textColor = theme.colors.secondaryText
        subtitleLabel.textColor = theme.colors.primaryText
        button.setTitleColor(theme.colors.link, for: .normal)
        button.backgroundColor = theme.colors.cardButtonBackground
    }
}

extension ReadMoreAboutRevertedEditViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        guard URL.absoluteString == editingGuidelines.urlString else {
            return false
        }
        return true
    }
}
