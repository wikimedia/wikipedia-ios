import UIKit
import WMF

protocol TalkPageTopicComposeViewControllerDelegate: AnyObject {
    func tappedPublish(topicTitle: String, topicBody: String, completion: (Result<Void, Error>) -> Void)
}

class TalkPageTopicComposeViewController: ViewController {
    
    enum TopicComposeStrings {
        static let navigationBarTitle = WMFLocalizedString("talk-pages-topic-compose-navbar-title", value: "Topic", comment: "Top navigation bar title of talk page topic compose screen.")
        static let titlePlaceholder = WMFLocalizedString("talk-pages-topic-compose-title-placeholder", value: "Topic title", comment: "Placeholder text in topic title field of the talk page topic compose screen.")
        static let bodyPlaceholder = WMFLocalizedString("talk-pages-topic-compose-body-placeholder", value: "Description", comment: "Placeholder text in topic body field of the talk page topic compose screen.")
        static let finePrintFormat = WMFLocalizedString("talk-page-topic-compose-terms-and-licenses", value: "By publishing changes, you agree to the %1$@Terms of Use%2$@, and you irrevocably agree to release your contribution under the %3$@CC BY-SA 3.0 License%4$@ and the %5$@GFDL%6$@.", comment: "Text for information about the Terms of Use and edit licenses on talk pages when composing a new topic. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting, %4$@ - app-specific non-text formatting, %5$@ - app-specific non-text formatting,  %6$@ - app-specific non-text formatting.")
    }
    
    private lazy var safeAreaBackgroundView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "close-inverse"), style: .plain, target: self, action: #selector(tappedClose))
        button.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return button
    }()
    
    lazy var publishButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: CommonStrings.publishTitle, style: .done, target: self, action: #selector(tappedPublish))
        button.isEnabled = false
        return button
    }()
    
    private lazy var containerScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.bounces = false
        return scrollView
    }()
    
    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16
        return stackView
    }()
    
    private lazy var inputContainerView: UIView = {
        let inputContainerView = UIView(frame: .zero)
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.cornerRadius = 8
        return inputContainerView
    }()
    
    private lazy var titleTextField: UITextField = {
        let textfield = UITextField(frame: .zero)
        textfield.translatesAutoresizingMaskIntoConstraints = false
        textfield.addTarget(self, action: #selector(titleTextFieldChanged), for: .editingChanged)
        return textfield
    }()
    
    private lazy var divView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var bodyTextView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.isScrollEnabled = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.delegate = self
        return textView
    }()
    
    private lazy var bodyPlaceholderLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = Self.TopicComposeStrings.bodyPlaceholder
        return label
    }()
    
    private lazy var finePrintTextView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = false
        return textView
    }()
    
    private var scrollViewBottomConstraint: NSLayoutConstraint?
    var delegate: TalkPageTopicComposeViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        
        setupNavigationBar()
        setupSafeAreaBackgroundView()
        setupContainerScrollView()
        setupContainerStackView()
        updateFonts()
        apply(theme: theme)
        self.title = Self.TopicComposeStrings.navigationBarTitle
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = publishButton
        navigationItem.leftBarButtonItem = closeButton
    }
    
    private func setupSafeAreaBackgroundView() {
        view.addSubview(safeAreaBackgroundView)
        
        NSLayoutConstraint.activate([
            safeAreaBackgroundView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            safeAreaBackgroundView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            safeAreaBackgroundView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            safeAreaBackgroundView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])
    }
    
    private func setupContainerScrollView() {
        view.addSubview(containerScrollView)
        
        let scrollViewBottomConstraint = view.layoutMarginsGuide.bottomAnchor.constraint(equalTo: containerScrollView.bottomAnchor)
        self.scrollViewBottomConstraint = scrollViewBottomConstraint
        
        NSLayoutConstraint.activate([
            containerScrollView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            containerScrollView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            containerScrollView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            scrollViewBottomConstraint
        ])
    }
    
    private func setupContainerStackView() {
        
        // Container Stack View
        containerScrollView.addSubview(containerStackView)
        containerScrollView.addSubview(bodyPlaceholderLabel)
        
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.topAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.trailingAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.leadingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: containerScrollView.contentLayoutGuide.bottomAnchor),
            
            // Ensures scroll view only scrolls vertically
            containerStackView.widthAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.widthAnchor),
            
            // Ensures content stretches at least to the bottom of the screen
            containerStackView.bottomAnchor.constraint(greaterThanOrEqualTo: containerScrollView.frameLayoutGuide.bottomAnchor)
        ])
        
        // Inner elements
        containerStackView.addArrangedSubview(inputContainerView)
        containerStackView.addArrangedSubview(finePrintTextView)
        
        inputContainerView.addSubview(titleTextField)
        inputContainerView.addSubview(divView)
        inputContainerView.addSubview(bodyTextView)
        
        titleTextField.setContentHuggingPriority(.required, for: .vertical)
        bodyTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
        finePrintTextView.setContentHuggingPriority(.required, for: .vertical)
        
        NSLayoutConstraint.activate([
            inputContainerView.widthAnchor.constraint(equalTo: containerStackView.readableContentGuide.widthAnchor),
            finePrintTextView.widthAnchor.constraint(equalTo: containerStackView.readableContentGuide.widthAnchor),
            
            titleTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16),
            titleTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 16),
            titleTextField.bottomAnchor.constraint(equalTo: divView.topAnchor, constant: -8),
            
            divView.heightAnchor.constraint(equalToConstant: (1 / UIScreen.main.scale)),
            divView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            divView.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            divView.bottomAnchor.constraint(equalTo: bodyTextView.topAnchor, constant: -16),
            
            bodyTextView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            bodyTextView.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16),
            bodyTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -16),
            
            bodyPlaceholderLabel.leadingAnchor.constraint(equalTo: bodyTextView.leadingAnchor),
            bodyPlaceholderLabel.topAnchor.constraint(equalTo: bodyTextView.topAnchor),
            bodyPlaceholderLabel.trailingAnchor.constraint(equalTo: bodyTextView.trailingAnchor)
        ])
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }
    
    func updateFonts() {
        titleTextField.font = UIFont.wmf_font(.headline, compatibleWithTraitCollection: traitCollection)
        bodyTextView.font = UIFont.wmf_font(.callout, compatibleWithTraitCollection: traitCollection)
        bodyPlaceholderLabel.font = UIFont.wmf_font(.callout, compatibleWithTraitCollection: traitCollection)
        finePrintTextView.attributedText = licenseTitleTextViewAttributedString
    }
    
    private var licenseTitleTextViewAttributedString: NSAttributedString {
        let localizedString = Self.TopicComposeStrings.finePrintFormat

        let substitutedString = String.localizedStringWithFormat(
            localizedString,
            "<a href=\"\(Licenses.saveTermsURL?.absoluteString ?? "")\">",
            "</a>",
            "<a href=\"\(Licenses.CCBYSA3URL?.absoluteString ?? "")\">",
            "</a>" ,
            "<a href=\"\(Licenses.GFDLURL?.absoluteString ?? "")\">",
            "</a>"
        )

        let attributedString = substitutedString.byAttributingHTML(with: .caption1, boldWeight: .regular, matching: traitCollection, color: theme.colors.primaryText, linkColor: theme.colors.link, tagMapping: nil, additionalTagAttributes: nil)

        return attributedString
    }
    
    override func keyboardDidChangeFrame(from oldKeyboardFrame: CGRect?, newKeyboardFrame: CGRect?) {
        super.keyboardDidChangeFrame(from: oldKeyboardFrame, newKeyboardFrame: newKeyboardFrame)
        
        guard oldKeyboardFrame != newKeyboardFrame else {
            return
        }
        
        guard let newKeyboardFrame = newKeyboardFrame else {
            scrollViewBottomConstraint?.constant = 0
            return
        }
        
        let safeAreaKeyboardFrame = safeAreaBackgroundView.frame.intersection(newKeyboardFrame)
        scrollViewBottomConstraint?.constant = safeAreaKeyboardFrame.height + view.directionalLayoutMargins.bottom
        
        view.setNeedsLayout()
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        
        navigationController?.navigationBar.titleTextAttributes = theme.navigationBarTitleTextAttributes
        view.backgroundColor = theme.colors.baseBackground
        closeButton.tintColor = theme.colors.tertiaryText
        publishButton.tintColor = theme.colors.link
        containerScrollView.backgroundColor = .clear
        containerStackView.backgroundColor = .clear
        inputContainerView.backgroundColor = theme.colors.paperBackground
        titleTextField.textColor = theme.colors.primaryText
        titleTextField.attributedPlaceholder = NSAttributedString(string: Self.TopicComposeStrings.titlePlaceholder, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.tertiaryText])
        bodyTextView.backgroundColor = theme.colors.paperBackground
        bodyTextView.textColor = theme.colors.primaryText
        bodyPlaceholderLabel.textColor = theme.colors.tertiaryText
        divView.backgroundColor = theme.colors.chromeShadow
        
        finePrintTextView.backgroundColor = theme.colors.baseBackground
        finePrintTextView.attributedText = licenseTitleTextViewAttributedString // TODO: not working? Link colors are off.
    }
    
    // MARK: Actions
    
    @objc private func tappedClose() {
        // TODO: Confirmation action sheet.
        dismiss(animated: true)
    }
    
    @objc private func tappedPublish() {
        guard let title = titleTextField.text,
              let body = bodyTextView.text,
              !title.isEmpty && !body.isEmpty else {
            assertionFailure("Title text field or body text view are empty. Publish button should have been disabled.")
            return
        }
        
        // TODO: Spinner somewhere while making call
        delegate?.tappedPublish(topicTitle: title, topicBody: body, completion: { result in
            switch result {
            case .success:
                // TODO: dismiss
                dismiss(animated: true)
            case .failure(let error):
                // TODO: show error banner of some sort
                print("error")
            }
        })
    }
    
    @objc private func titleTextFieldChanged() {
        evaluatePublishButtonEnabledState()
    }
    
    private func evaluatePublishButtonEnabledState() {
        publishButton.isEnabled = !(titleTextField.text ?? "").isEmpty && !bodyTextView.text.isEmpty
    }
}

extension TalkPageTopicComposeViewController: UITextViewDelegate {

     func textViewDidChange(_ textView: UITextView) {

         guard textView == bodyTextView else {
             return
         }

         bodyPlaceholderLabel.isHidden = bodyTextView.text.count == 0 ? false : true
         
         evaluatePublishButtonEnabledState()
     }
}
