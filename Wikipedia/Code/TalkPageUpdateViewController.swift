
import UIKit

protocol TalkPageUpdateDelegate: class {
    func tappedPublish(viewController: TalkPageUpdateViewController)
}

class TalkPageUpdateViewController: ViewController {
    
    enum UpdateType {
        case newDiscussion
        case newReply(discussion: TalkPageDiscussion)
    }
    
    weak var delegate: TalkPageUpdateDelegate?
    private let talkPage: TalkPage
    let updateType: UpdateType
    
    @IBOutlet private var titleTextField: ThemeableTextField!
    @IBOutlet private var bodyTextView: ThemeableTextView!
    @IBOutlet private var finePrintTextView: UITextView!
    
    @IBOutlet private var divViews: [UIView]!
    @IBOutlet private var containerViews: [UIView]!
    
    @IBOutlet private var firstDivView: UIView!
    @IBOutlet private var secondDivView: UIView!
    @IBOutlet private var subjectContainerView: UIView!
    @IBOutlet private var finePrintContainerView: UIView!
    @IBOutlet private var bodyContainerView: UIView!
    @IBOutlet private var bodyContainerVerticalPaddingConstraints: [NSLayoutConstraint]!
    
    @IBOutlet private var talkPageScrollView: UIScrollView!
    
    @IBOutlet private var bodyContainerViewHeightConstraint: NSLayoutConstraint!
    private var singleLineBodyHeight: CGFloat?
    private var oldBodyContainerHeight: CGFloat?
    private var keyboardIsUp = false
    
    private var licenseTitleTextViewAttributedString: NSAttributedString {
        let localizedString = WMFLocalizedString("talk-page-publish-terms-and-licenses", value: "By saving changes, you agree to the %1$@Terms of Use%2$@, and agree to release your contribution under the %3$@CC BY-SA 3.0%4$@ and the %5$@GFDL%6$@ licenses.", comment: "Text for information about the Terms of Use and edit licenses. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting, %4$@ - app-specific non-text formatting, %5$@ - app-specific non-text formatting,  %6$@ - app-specific non-text formatting.") //todo: gfd or gfdl?
        
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
    
    init(talkPage: TalkPage, type: UpdateType) {
        self.talkPage = talkPage
        self.updateType = type
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        scrollView = talkPageScrollView
        talkPageScrollView.keyboardDismissMode = .interactive
        super.viewDidLoad()

       commonSetup()
        switch updateType {
        case .newDiscussion:
            newDiscussionSetup()
        case .newReply:
            newReplySetup()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setBodyHeightIfNeeded()
    }
    
    private func commonSetup() {
        let publishButton = UIBarButtonItem(title: CommonStrings.publishTitle, style: .done, target: self, action: #selector(tappedPublish(_:)))
        navigationItem.rightBarButtonItem = publishButton
        navigationBar.updateNavigationItems()
        navigationBar.isBarHidingEnabled = false
        
        titleTextField.isUnderlined = false
        bodyTextView.isUnderlined = false
    }
    
    private func newDiscussionSetup() {
        title = WMFLocalizedString("talk-page-new-discussion-title", value: "New discussion", comment: "Title of page when composing a new discussion topic on talk pages.")
        
        titleTextField.placeholder = WMFLocalizedString("talk-page-new-subject-placeholder-text", value: "Subject", comment: "Placeholder text which appears initially in the new discussion subject field for talk pages.")
        
        calculateSingleLineBodyHeightIfNeeded()
    }
    
    private func newReplySetup() {
        bodyTextView.placeholder = WMFLocalizedString("talk-page-reply-body-placeholder-text", value: "Compose response", comment: "Placeholder text which appears initially in reply field for talk pages.")
        subjectContainerView.isHidden = true
        firstDivView.isHidden = true
    }
    
    private func calculateSingleLineBodyHeightIfNeeded() {
        if singleLineBodyHeight == nil {
            bodyTextView.text = nil
            bodyTextView.placeholder = "&nbsp;"
            bodyContainerViewHeightConstraint.isActive = false
            bodyTextView.setNeedsLayout()
            bodyTextView.layoutIfNeeded()
            
            var newHeight = bodyTextView.frame.height
            bodyContainerVerticalPaddingConstraints.forEach { newHeight += $0.constant  }
            singleLineBodyHeight = newHeight
            
            bodyTextView.placeholder = WMFLocalizedString("talk-page-new-body-placeholder-text", value: "Compose new discussion", comment: "Placeholder text which appears initially in the new discussion body field for talk pages.")
            bodyContainerViewHeightConstraint.isActive = true
            view.setNeedsLayout()
        }
    }
    
    private func setBodyHeightIfNeeded() {
        
        guard keyboardFrame == nil else {
           
            return
        }
        
        guard let singleLineBodyHeight = singleLineBodyHeight,
            let bodyContainerOrigin = bodyContainerView.superview?.convert(bodyContainerView.frame.origin, to: view) else {
            return
        }
        
        var newHeight = talkPageScrollView.frame.height - bodyContainerOrigin.y
        newHeight = newHeight - finePrintContainerView.frame.height - secondDivView.frame.height

        if bodyContainerViewHeightConstraint.constant != newHeight {
            if newHeight > singleLineBodyHeight {
                bodyContainerViewHeightConstraint.constant = newHeight
                bodyContainerViewHeightConstraint.isActive = true
            } else {
                bodyContainerViewHeightConstraint.isActive = false
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        titleTextField.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        bodyTextView.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        finePrintTextView.attributedText = licenseTitleTextViewAttributedString
        
        singleLineBodyHeight = nil
        calculateSingleLineBodyHeightIfNeeded()
    }
    
    @objc func tappedPublish(_ sender: UIBarButtonItem) {
        delegate?.tappedPublish(viewController: self)
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        containerViews.forEach { $0.backgroundColor = theme.colors.paperBackground }
        divViews.forEach { $0.backgroundColor = theme.colors.border }
        finePrintTextView.backgroundColor = theme.colors.paperBackground
        finePrintTextView.textColor = theme.colors.secondaryText
        
        titleTextField.apply(theme: theme)
        bodyTextView.apply(theme: theme)
        super.apply(theme: theme)
    }
}
