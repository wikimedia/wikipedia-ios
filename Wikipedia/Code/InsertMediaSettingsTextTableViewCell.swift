import WMFComponents

class InsertMediaSettingsTextTableViewCell: UITableViewCell {
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var footerLabel: UILabel!
    @IBOutlet private weak var textView: ThemeableTextView!
    @IBOutlet weak var learnMoreButton: UIButton!

    var headerText: String? {
        didSet {
            headerLabel.text = headerText
        }
    }

    var footerText: String? {
        didSet {
            footerLabel.text = footerText
        }
    }

    var learnMoreURL: URL?
    var learnMoreAction: ((URL) -> Void)?

    func textViewConfigured(with delegate: UITextViewDelegate, placeholder: String?, placeholderDelegate: ThemeableTextViewPlaceholderDelegate, clearDelegate: ThemeableTextViewClearDelegate, tag: Int) -> UITextView {
        textView._delegate = delegate
        textView.placeholderDelegate = placeholderDelegate
        textView.clearDelegate = clearDelegate
        textView.showsClearButton = true
        textView.placeholder = placeholder
        textView.textContainer.lineFragmentPadding = 0
        textView.tag = tag
        learnMoreButton.setTitle(CommonStrings.learnMoreTitle(), for: .normal)
        learnMoreButton.configuration?.contentInsets = .zero
        learnMoreButton.configuration?.titlePadding = .zero
        accessibilityElements = [headerLabel as Any, textView as Any, textView.clearButton as Any, footerLabel as Any]
        updateFonts()
        return textView
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        headerLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        footerLabel.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        textView.font = WMFFont.for(.callout, compatibleWith: traitCollection)
        learnMoreButton.titleLabel?.font =  WMFFont.for(.subheadline, compatibleWith: traitCollection)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        headerLabel.text = nil
        footerLabel.text = nil
        textView.reset()
    }

    @IBAction private func performLearnMoreAction(_ sender: UIButton) {
        guard let url = learnMoreURL else {
            assertionFailure("learnMoreURL should be set by now")
            return
        }
        learnMoreAction?(url)
    }
}

extension InsertMediaSettingsTextTableViewCell: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        headerLabel.textColor = theme.colors.secondaryText
        footerLabel.textColor = theme.colors.secondaryText
        textView.apply(theme: theme)
        learnMoreButton.setTitleColor(theme.colors.link, for: .normal)
    }
}
