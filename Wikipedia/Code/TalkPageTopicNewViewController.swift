
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
    
    @IBOutlet private var beKindContainerView: UIView!
    private var beKindView: InfoBannerView!
    @IBOutlet private var beKindContainerViewHeightConstraint: NSLayoutConstraint!
    private var beKindViewTopConstraint: NSLayoutConstraint!
    private var beKindViewBottomConstraint: NSLayoutConstraint!
    private var beKindViewHeightConstraint: NSLayoutConstraint!
    
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
        let localizedString = WMFLocalizedString("talk-page-publish-terms-and-licenses", value: "By saving changes, you agree to the %1$@Terms of Use%2$@, and agree to release your contribution under the %3$@CC BY-SA 3.0%4$@ and the %5$@GFDL%6$@ licenses.", comment: "Text for information about the Terms of Use and edit licenses on talk pages. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting, %4$@ - app-specific non-text formatting, %5$@ - app-specific non-text formatting,  %6$@ - app-specific non-text formatting.") //todo: gfd or gfdl?
        
        let substitutedString = String.localizedStringWithFormat(
            localizedString,
            "<a href=\"\(Licenses.saveTermsURL?.absoluteString ?? "")\">",
            "</a>",
            "<a href=\"\(Licenses.CCBYSA3URL?.absoluteString ?? "")\">",
            "</a>" ,
            "<a href=\"\(Licenses.GFDLURL?.absoluteString ?? "")\">",
            "</a>"
        )
        
        let attributedString = substitutedString.byAttributingHTML(with: .caption1, boldWeight: .regular, matching: traitCollection, withBoldedString: nil, color: theme.colors.secondaryText, linkColor: theme.colors.link, tagMapping: nil, additionalTagAttributes: nil)
        
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
        setupBeKindContainerView()
        setupBackgroundTap()
        talkPageScrollView.keyboardDismissMode = .interactive
        
        calculateSingleLineBodyHeightIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setBodyHeightIfNeeded()
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
    
    override func keyboardWillChangeFrame(_ notification: Notification) {
        
        super.keyboardWillChangeFrame(notification)
        
        if let keyboardFrame = keyboardFrame {
            
            if keyboardFrame.height == 0 {
                return
            }
            
            var convertedBeKindViewFrame = beKindContainerView.convert(beKindView.frame, to: view)
            convertedBeKindViewFrame.origin.y = keyboardFrame.minY - beKindContainerView.frame.height
            let newBeKindViewFrame = view.convert(convertedBeKindViewFrame, to: beKindContainerView)
            
            beKindViewTopConstraint.constant = newBeKindViewFrame.minY
            beKindViewBottomConstraint.isActive = false
            beKindContainerViewHeightConstraint.constant = 0
            
            let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.2
            let curve = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UIView.AnimationOptions) ?? UIView.AnimationOptions.curveLinear
            
            UIView.animate(withDuration: duration, delay: 0.0, options: curve, animations: {
                self.view.layoutIfNeeded()
             }, completion: nil)
        }
        
    }
    
    override func keyboardWillHide(_ notification: Notification) {
        super.keyboardWillHide(notification)
        
        let keyboardAnimationDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.2
        let duration = keyboardAnimationDuration == 0 ? 0.2 : keyboardAnimationDuration
        
        beKindViewTopConstraint.constant = 0
        beKindViewBottomConstraint.isActive = true
        beKindContainerViewHeightConstraint.constant = beKindViewHeightConstraint.constant
        
        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateFonts()
        
        singleLineBodyHeight = nil
        calculateSingleLineBodyHeightIfNeeded()
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        containerViews.forEach { $0.backgroundColor = theme.colors.paperBackground }
        divViews.forEach { $0.backgroundColor = theme.colors.border }
        finePrintTextView.backgroundColor = theme.colors.paperBackground
        finePrintTextView.textColor = theme.colors.secondaryText
        beKindView?.apply(theme: theme)
        beKindContainerView.backgroundColor = theme.colors.paperBackground
        subjectTextField.apply(theme: theme)
        bodyTextView.apply(theme: theme)
        super.apply(theme: theme)
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
        bodyTextView.isUnderlined = false
        bodyTextView._delegate = self
        
        subjectTextField.placeholder = WMFLocalizedString("talk-page-new-subject-placeholder-text", value: "Subject", comment: "Placeholder text which appears initially in the new topic subject field for talk pages.")
        
        subjectTextField.addTarget(self, action: #selector(evaluatePublishButtonState), for: .editingChanged)
    }
    
    func setupBeKindContainerView() {
        
        guard let view = view else {
            return
        }
        
        beKindView = InfoBannerView()
        beKindView.apply(theme: theme)
        beKindView.configure(iconName: "heart-icon", title: CommonStrings.talkPageNewBannerTitle, subtitle: CommonStrings.talkPageNewBannerSubtitle)
        beKindContainerViewHeightConstraint.constant = beKindView.sizeThatFits(view.bounds.size, apply: true).height
        beKindViewHeightConstraint = beKindView.heightAnchor.constraint(equalToConstant: beKindContainerViewHeightConstraint.constant)
        beKindViewHeightConstraint.priority = .defaultHigh
        
        beKindView.translatesAutoresizingMaskIntoConstraints = false
        beKindContainerView.addSubview(beKindView)
        beKindViewTopConstraint = beKindView.topAnchor.constraint(equalTo: beKindContainerView.topAnchor)
        beKindViewBottomConstraint = beKindView.bottomAnchor.constraint(equalTo: beKindContainerView.bottomAnchor)
        let trailingConstraint = beKindView.trailingAnchor.constraint(equalTo: beKindContainerView.trailingAnchor)
        let leadingConstraint = beKindView.leadingAnchor.constraint(equalTo: beKindContainerView.leadingAnchor)
        NSLayoutConstraint.activate([beKindViewTopConstraint, beKindViewBottomConstraint, trailingConstraint, leadingConstraint, beKindViewHeightConstraint])
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
            } else if bodyTextView.isShowingPlaceholder {
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
        var contentFittingBodyContainerHeight = bodyTextView.frame.height
        bodyContainerVerticalPaddingConstraints.forEach { contentFittingBodyContainerHeight += $0.constant  }
        
        var availableVerticalScreenSpace = talkPageScrollView.frame.height - bodyContainerOrigin.y
        availableVerticalScreenSpace = availableVerticalScreenSpace - finePrintContainerView.frame.height - beKindContainerView.frame.height
        
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
