import UIKit
import WMF

protocol TalkPageReplyComposeDelegate: AnyObject {
    func tappedClose()
    func tappedPublish(text: String, commentViewModel: TalkPageCellCommentViewModel)
}

class TalkPageReplyComposeContentView: SetupView {
    
    private lazy var publishButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(CommonStrings.publishTitle, for: .normal)
        button.addTarget(self, action: #selector(tappedPublish), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.preservesSuperviewLayoutMargins = true
        return button
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "close-inverse"), for: .normal)
        button.addTarget(self, action: #selector(tappedClose), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.preservesSuperviewLayoutMargins = true
        button.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
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
    
    private lazy var replyTextView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.delegate = self
        return textView
    }()
    
    private lazy var finePrintTextView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = false
        return textView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel(frame: .zero)
        // todo: localization, dynamic
        label.text = "Reply to DavidDavid"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .natural
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
    private weak var delegate: TalkPageReplyComposeDelegate?
    
    // MARK: Lifecycle
    
    init(commentViewModel: TalkPageCellCommentViewModel, theme: Theme, delegate: TalkPageReplyComposeDelegate) {
        self.commentViewModel = commentViewModel
        self.theme = theme
        self.delegate = delegate
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
        apply(theme: theme)
    }
    
    // MARK: Setup
    
    private func setupPublishButton() {
        addSubview(publishButton)
        
        publishButton.setContentHuggingPriority(.required, for: .vertical)
        publishButton.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let topConstraint = layoutMarginsGuide.topAnchor.constraint(equalTo: publishButton.topAnchor)
        let trailingConstraint = layoutMarginsGuide.trailingAnchor.constraint(equalTo: publishButton.trailingAnchor)
        
        NSLayoutConstraint.activate([trailingConstraint, topConstraint])
        
        publishButton.titleLabel?.font = UIFont.wmf_scaledSystemFont(forTextStyle: .subheadline, weight: .bold, size: 15.0)
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
        verticalStackView.spacing = 5
        
        let topConstraint = verticalStackView.topAnchor.constraint(equalTo: containerScrollView.topAnchor)
        let trailingConstraint = containerScrollView.trailingAnchor.constraint(greaterThanOrEqualTo: verticalStackView.trailingAnchor)
        let leadingConstraint = verticalStackView.leadingAnchor.constraint(greaterThanOrEqualTo: containerScrollView.leadingAnchor)
        let bottomConstraint = containerScrollView.bottomAnchor.constraint(equalTo: verticalStackView.bottomAnchor)
        let centerXConstraint = verticalStackView.centerXAnchor.constraint(equalTo: containerScrollView.centerXAnchor)
        
        let bottomContainerConstraint = safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: verticalStackView.bottomAnchor)
        bottomContainerConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([topConstraint, trailingConstraint, leadingConstraint, bottomConstraint, bottomContainerConstraint, centerXConstraint])
    }
    
    private func setupReplyTextView() {
        verticalStackView.addArrangedSubview(replyTextView)
        
        replyTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
        replyTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        readableContentGuide.widthAnchor.constraint(equalTo: replyTextView.widthAnchor).isActive = true

        replyTextView.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    private func setupFinePrintTextView() {
        verticalStackView.addArrangedSubview(finePrintTextView)
        
        finePrintTextView.setContentHuggingPriority(.required, for: .vertical)
        finePrintTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        finePrintTextView.widthAnchor.constraint(equalTo: replyTextView.widthAnchor).isActive = true
        
        // TODO: tap link responding
    }
    
    private func setupPlaceholderLabel() {
        containerScrollView.addSubview(placeholderLabel)
        
        let topConstraint = replyTextView.topAnchor.constraint(equalTo: placeholderLabel.topAnchor)
        let trailingConstraint = replyTextView.trailingAnchor.constraint(equalTo: placeholderLabel.trailingAnchor)
        let leadingConstraint = replyTextView.leadingAnchor.constraint(equalTo: placeholderLabel.leadingAnchor)
        
        NSLayoutConstraint.activate([topConstraint, trailingConstraint, leadingConstraint])
        
        placeholderLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    private func setupInfoButton() {
        infoButton.setContentHuggingPriority(.required, for: .vertical)
        infoButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    // MARK: Actions
    
    @objc private func tappedClose() {
        replyTextView.resignFirstResponder()
        delegate?.tappedClose()
    }
    
    @objc private func tappedInfo() {
        toggleFinePrint(shouldShow: true)
    }
    
    @objc private func tappedPublish() {
        delegate?.tappedPublish(text: replyTextView.text, commentViewModel: commentViewModel)
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
        let localizedString = WMFLocalizedString("talk-page-reply-terms-and-licenses", value: "Note your reply will be automatically signed with your username. By saving changes, you agree to the %1$@Terms of Use%2$@, and agree to release your contribution under the %3$@CC BY-SA 3.0%4$@ and the %5$@GFDL%6$@ licenses.", comment: "Text for information about the Terms of Use and edit licenses on talk pages when replying. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting, %4$@ - app-specific non-text formatting, %5$@ - app-specific non-text formatting,  %6$@ - app-specific non-text formatting.")
        
        let substitutedString = String.localizedStringWithFormat(
            localizedString,
            "<a href=\"\(Licenses.saveTermsURL?.absoluteString ?? "")\">",
            "</a>",
            "<a href=\"\(Licenses.CCBYSA3URL?.absoluteString ?? "")\">",
            "</a>" ,
            "<a href=\"\(Licenses.GFDLURL?.absoluteString ?? "")\">",
            "</a>"
        )
        
        let attributedString = substitutedString.byAttributingHTML(with: .caption1, boldWeight: .regular, matching: traitCollection, color: theme.colors.secondaryText, linkColor: theme.colors.link, tagMapping: nil, additionalTagAttributes: nil)
        
        return attributedString
    }
}

extension TalkPageReplyComposeContentView: UITextViewDelegate {

     func textViewDidChange(_ textView: UITextView) {

         guard textView == replyTextView else {
             return
         }

         placeholderLabel.alpha = replyTextView.text.count == 0 ? 1 : 0
         toggleFinePrint(shouldShow: false)
     }
     
     func textViewDidBeginEditing(_ textView: UITextView) {
         
         guard textView == replyTextView else {
             return
         }
         
         placeholderLabel.alpha = 0
         toggleFinePrint(shouldShow: false)
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
        
        closeButton.tintColor = theme.colors.tertiaryText // todo: better color
        publishButton.tintColor = theme.colors.link
    }
}
