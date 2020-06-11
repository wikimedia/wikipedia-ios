
import UIKit

protocol TalkPageTopicNewViewControllerDelegate: class {
    func tappedPublish(subject: String, body: String, viewController: TalkPageTopicNewViewController)
}

class TalkPageTopicNewViewController: ViewController {

    weak var delegate: TalkPageTopicNewViewControllerDelegate?
    
    @IBOutlet private var stackView: UIStackView!
    @IBOutlet private var subjectTextField: ThemeableTextField!
    @IBOutlet private var bodyTextView: ThemeableTextView!
    @IBOutlet private var finePrintTextView: UITextView!
    
    @IBOutlet private var divViews: [UIView]!
    @IBOutlet private var containerViews: [UIView]!

    private lazy var beKindInputAccessoryView: BeKindInputAccessoryView = {
        return BeKindInputAccessoryView.wmf_viewFromClassNib()
    }()

    @IBOutlet private var finePrintContainerView: UIView!
    @IBOutlet private var bodyContainerView: UIView!
    @IBOutlet private var bodyContainerVerticalPaddingConstraints: [NSLayoutConstraint]!
    
    @IBOutlet private var talkPageScrollView: UIScrollView!
    
    @IBOutlet private var bodyContainerViewHeightConstraint: NSLayoutConstraint!
    
    private var singleLineBodyHeight: CGFloat?
    
    private var backgroundTapGestureRecognizer: UITapGestureRecognizer!
    private var publishButton: UIBarButtonItem!

    private var bodyPlaceholder: String {
        return WMFLocalizedString("talk-page-new-topic-body-placeholder-text", value: "Compose new discussion", comment: "Placeholder text which appears initially in the new topic body field for talk pages.")
    }
    
    private var licenseTitleTextViewAttributedString: NSAttributedString {
        let localizedString = WMFLocalizedString("talk-page-publish-terms-and-licenses", value: "By saving changes, you agree to the %1$@Terms of Use%2$@, and agree to release your contribution under the %3$@CC BY-SA 3.0%4$@ and the %5$@GFDL%6$@ licenses.", comment: "Text for information about the Terms of Use and edit licenses on talk pages. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting, %4$@ - app-specific non-text formatting, %5$@ - app-specific non-text formatting,  %6$@ - app-specific non-text formatting.")
        
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
    
    lazy private var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        progressController.delay = 0.0
        return progressController
    }()
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        scrollView = talkPageScrollView
        
        super.viewDidLoad()

        setupNavigationBar()
        setupTextInputViews()
        setupBackgroundTap()
        talkPageScrollView.keyboardDismissMode = .interactive
        
        calculateSingleLineBodyHeightIfNeeded()

        subjectTextField.inputAccessoryView = beKindInputAccessoryView
        bodyTextView.inputAccessoryView = beKindInputAccessoryView
        beKindInputAccessoryView.delegate = self
        updateFonts()
        apply(theme: theme)
    }

    override var inputAccessoryView: UIView? {
        return beKindInputAccessoryView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        beKindInputAccessoryView.containerHeight = view.bounds.height
        setBodyHeightIfNeeded()
        updateContentInsets()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateContentInsets()
    }
    
    override func keyboardWillChangeFrame(_ notification: Notification) {
        super.keyboardWillChangeFrame(notification)
        updateContentInsets()
    }
    
    func postDidBegin() {
        fakeProgressController.start()
        publishButton.isEnabled = false
        subjectTextField.isUserInteractionEnabled = false
        bodyTextView.isUserInteractionEnabled = false
    }
    
    func postDidEnd() {
        fakeProgressController.stop()
        publishButton.isEnabled = true
        subjectTextField.isUserInteractionEnabled = true
        bodyTextView.isUserInteractionEnabled = true
    }
    
    func announcePostSuccessful() {
        NotificationCenter.default.addObserver(self, selector: #selector(announcementDidFinish(notification:)), name: UIAccessibility.announcementDidFinishNotification, object: nil)
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.successfullyPublishedDiscussion)
    }
    
    @objc private func announcementDidFinish(notification: NSNotification) {
         navigationController?.popViewController(animated: true)
        NotificationCenter.default.removeObserver(self, name: UIAccessibility.announcementDidFinishNotification, object: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateFonts()
        
        singleLineBodyHeight = nil
        calculateSingleLineBodyHeightIfNeeded()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        containerViews.forEach { $0.backgroundColor = theme.colors.paperBackground }
        divViews.forEach { $0.backgroundColor = theme.colors.border }
        finePrintTextView.backgroundColor = theme.colors.paperBackground
        finePrintTextView.textColor = theme.colors.secondaryText
        beKindInputAccessoryView.apply(theme: theme)
        subjectTextField.apply(theme: theme)
        bodyTextView.apply(theme: theme)
    }
}

//MARK: Private

private extension TalkPageTopicNewViewController {
    
    func setupNavigationBar() {
        publishButton = UIBarButtonItem(title: CommonStrings.publishTitle, style: .done, target: self, action: #selector(tappedPublish(_:)))
        publishButton.isEnabled = false
        publishButton.tintColor = theme.colors.link
        navigationItem.rightBarButtonItem = publishButton
        navigationBar.updateNavigationItems()
        navigationBar.isBarHidingEnabled = false
        
        title = WMFLocalizedString("talk-page-new-topic-title", value: "New discussion", comment: "Title of page when composing a new topic on talk pages.")
    }
    
    func setupTextInputViews() {
        subjectTextField.isUnderlined = false
        subjectTextField.accessibilityLabel = WMFLocalizedString("talk-page-new-subject-textfield-accessibility-label", value: "Subject", comment: "Accessibility label for subject text field.")
        bodyTextView.accessibilityLabel = WMFLocalizedString("talk-page-new-body-textfield-accessibility-label", value: "Discussion Body", comment: "Accessibility label for discussion body text field.")
        bodyTextView.isUnderlined = false
        bodyTextView._delegate = self
        
        subjectTextField.placeholder = WMFLocalizedString("talk-page-new-subject-placeholder-text", value: "Subject", comment: "Placeholder text which appears initially in the new topic subject field for talk pages.")
        
        let clearAccessibilityLabel = WMFLocalizedString("talk-page-new-subject-clear-button-accessibility", value: "Clear subject", comment: "Accessibility label for the clear values X button in the talk page new subject textfield.")
        subjectTextField.clearAccessibilityLabel = clearAccessibilityLabel
        
        subjectTextField.addTarget(self, action: #selector(evaluatePublishButtonState), for: .editingChanged)
    }
    
    func setupBackgroundTap() {
        backgroundTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedBackground(_:)))
        view.addGestureRecognizer(backgroundTapGestureRecognizer)
    }
    
    @objc func tappedBackground(_ tapGestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc func tappedPublish(_ sender: UIBarButtonItem) {
        guard let subjectText = subjectTextField.text,
            let bodyText = bodyTextView.text else {
                return
        }
        
        delegate?.tappedPublish(subject: subjectText, body: bodyText, viewController: self)
    }
    
    func calculateSingleLineBodyHeightIfNeeded() {
        if singleLineBodyHeight == nil {
            let oldText = bodyTextView.text
            bodyTextView.text = "&nbsp;"
            bodyContainerViewHeightConstraint.isActive = false
            bodyTextView.setNeedsLayout()
            bodyTextView.layoutIfNeeded()
            
            var newHeight = bodyTextView.frame.height
            bodyContainerVerticalPaddingConstraints.forEach { newHeight += $0.constant  }
            singleLineBodyHeight = newHeight
            
            if let oldText = oldText, oldText.count > 0 {
                bodyTextView.text = oldText
                bodyTextView.placeholder = nil
            } else if bodyTextView.isShowingPlaceholder && !UIAccessibility.isVoiceOverRunning {
                bodyTextView.placeholder = bodyPlaceholder
            } else {
                bodyTextView.text = nil
            }
            
            bodyContainerViewHeightConstraint.isActive = true
            view.setNeedsLayout()
        }
    }
    
    func setBodyHeightIfNeeded() {
        
        guard let singleLineBodyHeight = singleLineBodyHeight,
            let bodyContainerOrigin = bodyContainerView.superview?.convert(bodyContainerView.frame.origin, to: view) else {
                return
        }
        
        //first get the size bodyTextView wants to be without a height limit (bodyTextView.contentSize.height doesn't seem reliable here)
        bodyContainerViewHeightConstraint.isActive = false
        bodyTextView.setNeedsLayout()
        bodyTextView.layoutIfNeeded()
        finePrintContainerView.setNeedsLayout()
        finePrintContainerView.layoutIfNeeded()
        var contentFittingBodyContainerHeight = bodyTextView.frame.height
        bodyContainerVerticalPaddingConstraints.forEach { contentFittingBodyContainerHeight += $0.constant  }
        
        var availableVerticalScreenSpace = talkPageScrollView.frame.height - bodyContainerOrigin.y
        availableVerticalScreenSpace = availableVerticalScreenSpace - finePrintContainerView.frame.height - beKindInputAccessoryView.height
        
        if bodyContainerViewHeightConstraint.constant != availableVerticalScreenSpace {
            if availableVerticalScreenSpace > singleLineBodyHeight && availableVerticalScreenSpace >= contentFittingBodyContainerHeight {
                bodyContainerViewHeightConstraint.constant = availableVerticalScreenSpace
                bodyContainerViewHeightConstraint.isActive = true
            } else {
                bodyContainerViewHeightConstraint.isActive = false
            }
        } else {
            bodyContainerViewHeightConstraint.isActive = true
        }
    }
    
    func updateContentInsets() {
        if (!bodyContainerViewHeightConstraint.isActive) {
            talkPageScrollView.contentInset.bottom += beKindInputAccessoryView.height
        }
    }
    
    @objc func evaluatePublishButtonState() {
        publishButton.isEnabled = (subjectTextField.text?.count ?? 0) > 0 && (bodyTextView.text?.count ?? 0) > 0
    }
    
    func updateFonts() {
        subjectTextField.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        bodyTextView.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        finePrintTextView.attributedText = licenseTitleTextViewAttributedString
    }
}

//MARK: ThemeableTextViewPlaceholderDelegate

extension TalkPageTopicNewViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        evaluatePublishButtonState()
    }
}

//MARK: BeKindInputAccessoryViewDelegate

extension TalkPageTopicNewViewController: BeKindInputAccessoryViewDelegate {
    func didUpdateHeight(view: BeKindInputAccessoryView) {
        setBodyHeightIfNeeded()
    }
}
