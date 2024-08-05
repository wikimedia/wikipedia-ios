import WMFComponents
import WMF

class TalkPageReplyComposeContentView: SetupView {
    
    private(set) lazy var publishButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(CommonStrings.publishTitle, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.preservesSuperviewLayoutMargins = true
        return button
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = theme.colors.primaryText
        return activityIndicator
    }()
    
    private(set) lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "close-inverse"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.preservesSuperviewLayoutMargins = true
        button.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        button.accessibilityHint = WMFLocalizedString("talk-page-rply-close-button-accessibility-hint", value: "Close reply view", comment: "Accessibility hint for the reply screen close button")
        return button
    }()
    
    private lazy var containerScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.preservesSuperviewLayoutMargins = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.bounces = false
        return scrollView
    }()
    
    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = true
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        return stackView
    }()
    
    private(set) lazy var replyTextView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.smartQuotesType = .no
        return textView
    }()
    
    private lazy var finePrintTextView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.delegate = self
        return textView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .natural
        label.isAccessibilityElement = false
        return label
    }()
    
    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .custom)

        button.setImage(UIImage(systemName: "info.circle"), for: .normal)
        button.addTarget(self, action: #selector(tappedInfo), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private(set) var commentViewModel: TalkPageCellCommentViewModel
    private var theme: Theme
    private weak var linkDelegate: TalkPageTextViewLinkHandling?
    
    // MARK: Lifecycle
    
    init(commentViewModel: TalkPageCellCommentViewModel, theme: Theme, linkDelegate: TalkPageTextViewLinkHandling) {
        self.commentViewModel = commentViewModel
        self.theme = theme
        self.linkDelegate = linkDelegate
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16)
        setupPublishButton()
        setupCloseButton()
        setupContainerScrollView()
        setupStackView()
        setupReplyTextView()
        setupFinePrintTextView()
        setupPlaceholderLabel()
        setupInfoButton()
        updateFonts()
        apply(theme: theme)
        
        guard let semanticContentAttribute = commentViewModel.cellViewModel?.viewModel?.semanticContentAttribute else {
            return
        }
        
        updateSemanticContentAttribute(semanticContentAttribute)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
        apply(theme: theme)
    }
    
    // MARK: Public
    
    var isLoading: Bool = false {
        didSet {
            publishButton.isHidden = isLoading ? true : false
            if isLoading {
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
            } else {
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
            }
        }
    }
    
    // MARK: Setup
    
    private func setupPublishButton() {
        addSubview(publishButton)
        addSubview(activityIndicator)
        
        publishButton.setContentHuggingPriority(.required, for: .vertical)
        publishButton.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            layoutMarginsGuide.topAnchor.constraint(equalTo: publishButton.topAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: publishButton.trailingAnchor),
            activityIndicator.topAnchor.constraint(equalTo: publishButton.topAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: publishButton.trailingAnchor)
        ])
        
        activityIndicator.isHidden = true

        publishButton.isEnabled = false
    }
    
    private func setupCloseButton() {
        addSubview(closeButton)
        
        closeButton.setContentHuggingPriority(.required, for: .vertical)
        closeButton.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let centerYConstraint = closeButton.centerYAnchor.constraint(equalTo: publishButton.centerYAnchor)
        let leadingConstraint = layoutMarginsGuide.leadingAnchor.constraint(equalTo: closeButton.leadingAnchor)
        
        NSLayoutConstraint.activate([centerYConstraint, leadingConstraint])
    }
    
    private func setupContainerScrollView() {
        addSubview(containerScrollView)
        
        let topConstraint = containerScrollView.topAnchor.constraint(equalTo: publishButton.bottomAnchor, constant: 5)
        let trailingConstraint = safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: containerScrollView.trailingAnchor)
        let leadingConstraint = safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: containerScrollView.leadingAnchor)
        let bottomConstraint = safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: containerScrollView.bottomAnchor)
        NSLayoutConstraint.activate([topConstraint, trailingConstraint, leadingConstraint, bottomConstraint])
    }
    
    private func setupStackView() {
        containerScrollView.addSubview(verticalStackView)
        
        verticalStackView.spacing = traitCollection.preferredContentSizeCategory <= .extraExtraExtraLarge ? 5 : 50
        
        let topConstraint = verticalStackView.topAnchor.constraint(equalTo: containerScrollView.topAnchor)
        let trailingConstraint = containerScrollView.trailingAnchor.constraint(greaterThanOrEqualTo: verticalStackView.trailingAnchor)
        let leadingConstraint = verticalStackView.leadingAnchor.constraint(greaterThanOrEqualTo: containerScrollView.leadingAnchor)
        let bottomConstraint = containerScrollView.bottomAnchor.constraint(equalTo: verticalStackView.bottomAnchor)
        let centerXConstraint = verticalStackView.centerXAnchor.constraint(equalTo: containerScrollView.centerXAnchor)
        
        let bottomContainerConstraint = safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: verticalStackView.bottomAnchor, constant: 5)
        bottomContainerConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([topConstraint, trailingConstraint, leadingConstraint, bottomConstraint, bottomContainerConstraint, centerXConstraint])
    }
    
    private func setupReplyTextView() {
        verticalStackView.addArrangedSubview(replyTextView)
        
        replyTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
        replyTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        readableContentGuide.widthAnchor.constraint(equalTo: replyTextView.widthAnchor).isActive = true
    }
    
    private func setupFinePrintTextView() {
        verticalStackView.addArrangedSubview(finePrintTextView)
        
        finePrintTextView.setContentHuggingPriority(.required, for: .vertical)
        finePrintTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        finePrintTextView.widthAnchor.constraint(equalTo: replyTextView.widthAnchor).isActive = true
    }
    
    private func setupPlaceholderLabel() {
        
        let placeholderText = String.localizedStringWithFormat(WMFLocalizedString("talk-page-reply-placeholder-format", value: "Reply to %1$@", comment: "Placeholder text that displays in the talk page reply text view. Parameters:\n* %1$@ - the username of the comment the user is replying to. Please prioritize for de, ar and zh wikis."), commentViewModel.author)
        placeholderLabel.text = placeholderText
        replyTextView.accessibilityHint = placeholderText
        
        containerScrollView.addSubview(placeholderLabel)
        
        let topConstraint = replyTextView.topAnchor.constraint(equalTo: placeholderLabel.topAnchor)
        let trailingConstraint = replyTextView.trailingAnchor.constraint(equalTo: placeholderLabel.trailingAnchor)
        let leadingConstraint = replyTextView.leadingAnchor.constraint(equalTo: placeholderLabel.leadingAnchor)
        
        NSLayoutConstraint.activate([topConstraint, trailingConstraint, leadingConstraint])
    }
    
    private func setupInfoButton() {
        infoButton.setContentHuggingPriority(.required, for: .vertical)
        infoButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    private func updateSemanticContentAttribute(_ semanticContentAttribute: UISemanticContentAttribute) {
        
        verticalStackView.semanticContentAttribute = semanticContentAttribute
        replyTextView.semanticContentAttribute = semanticContentAttribute
        finePrintTextView.semanticContentAttribute = semanticContentAttribute
        placeholderLabel.semanticContentAttribute = semanticContentAttribute
        infoButton.semanticContentAttribute = semanticContentAttribute
        
        replyTextView.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        finePrintTextView.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        placeholderLabel.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
    }
    
    private func updateFonts() {
        publishButton.titleLabel?.font = WMFFont.for(.boldSubheadline, compatibleWith: traitCollection)
        replyTextView.font = WMFFont.for(.callout, compatibleWith: traitCollection)
        placeholderLabel.font = WMFFont.for(.callout, compatibleWith: traitCollection)
    }
    
    // MARK: Actions
    
    @objc private func tappedInfo() {
        toggleFinePrint(shouldShow: true)
    }
    
    // MARK: Helpers
    
    private func toggleFinePrint(shouldShow: Bool) {
        if shouldShow {
            infoButton.removeFromSuperview()
            verticalStackView.addArrangedSubview(finePrintTextView)
            finePrintTextView.widthAnchor.constraint(equalTo: replyTextView.widthAnchor).isActive = true
        } else {
            finePrintTextView.removeFromSuperview()
            verticalStackView.addArrangedSubview(infoButton)
        }
    }
    
    private var licenseTitleTextViewAttributedString: NSAttributedString {
        let localizedString = WMFLocalizedString("talk-page-reply-terms-and-licenses-ccsa4", value: "Note your reply will be automatically signed with your username. By saving changes, you agree to the %1$@Terms of Use%2$@, and agree to release your contribution under the %3$@CC BY-SA 4.0%4$@ and the %5$@GFDL%6$@ licenses.", comment: "Text for information about the Terms of Use and edit licenses on talk pages when replying. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting, %4$@ - app-specific non-text formatting, %5$@ - app-specific non-text formatting,  %6$@ - app-specific non-text formatting. Please prioritize for de, ar and zh wikis.")
        
        let substitutedString = String.localizedStringWithFormat(
            localizedString,
            "<a href=\"\(Licenses.saveTermsURL?.absoluteString ?? "")\">",
            "</a>",
            "<a href=\"\(Licenses.CCBYSA4URL?.absoluteString ?? "")\">",
            "</a>" ,
            "<a href=\"\(Licenses.GFDLURL?.absoluteString ?? "")\">",
            "</a>"
        )

        return NSAttributedString.attributedStringFromHtml(substitutedString, styles: styles)
    }

    private var styles: HtmlUtils.Styles {
        HtmlUtils.Styles(font: WMFFont.for(.caption1, compatibleWith: traitCollection), boldFont: WMFFont.for(.caption1, compatibleWith: traitCollection), italicsFont: WMFFont.for(.caption1, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.caption1, compatibleWith: traitCollection), color: theme.colors.secondaryText, linkColor: theme.colors.link, lineSpacing: 1)
    }

    private func evaluatePublishButtonEnabledState() {
        let isEnabled = !replyTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        publishButton.isEnabled = isEnabled
    }

}

extension TalkPageReplyComposeContentView: UITextViewDelegate {

     func textViewDidChange(_ textView: UITextView) {
         guard textView == replyTextView else {
             return
         }

         placeholderLabel.alpha = replyTextView.text.count == 0 ? 1 : 0
         toggleFinePrint(shouldShow: false)
         evaluatePublishButtonEnabledState()
     }
     
     func textViewDidBeginEditing(_ textView: UITextView) {
         guard textView == replyTextView else {
             return
         }
         
         placeholderLabel.alpha = 0
         toggleFinePrint(shouldShow: false)
     }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        linkDelegate?.tappedLink(URL, sourceTextView: textView)
        return false
    }
}

extension TalkPageReplyComposeContentView: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        
        backgroundColor = theme.colors.paperBackground
        replyTextView.backgroundColor = theme.colors.paperBackground
        replyTextView.textColor = theme.colors.primaryText
        placeholderLabel.textColor = theme.colors.secondaryText
        
        finePrintTextView.backgroundColor = theme.colors.paperBackground
        finePrintTextView.textColor = theme.colors.secondaryText
        finePrintTextView.attributedText = licenseTitleTextViewAttributedString
        
        closeButton.tintColor = theme.colors.tertiaryText
        publishButton.tintColor = theme.colors.link
        
        let currentSemanticContentAttribute = verticalStackView.semanticContentAttribute
        updateSemanticContentAttribute(currentSemanticContentAttribute)
    }
}
