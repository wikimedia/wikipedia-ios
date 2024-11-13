import Foundation
import WMFComponents
import WMF

protocol TalkPageReplyComposeDelegate: AnyObject {
    func closeReplyView()
    func tappedPublish(text: String, commentViewModel: TalkPageCellCommentViewModel)
}

/// Class for coordinating talk page reply compose views
class TalkPageReplyComposeController {
    
    enum ActionSheetStrings {
        static let closeConfirmationTitle = WMFLocalizedString("talk-pages-reply-compose-close-confirmation-title", value: "Are you sure you want to discard this new reply?", comment: "Title of confirmation alert displayed to user when they attempt to close the new reply view after entering text. Please prioritize for de, ar and zh wikis.")
        static let closeConfirmationDiscard = WMFLocalizedString("talk-pages-topic-compose-close-confirmation-discard-reply", value: "Discard Reply", comment: "Title of discard action, displayed within a confirmation alert to user when they attempt to close the reply view after entering reply text.")
    }
    
    // viewController - the view controller that triggered the reply compose screen
    // containerView - the view that contains the contentView. It has the drag handle and pan gesture attached.
    // contentView - the view with the reply compose UI elements (close button, publish button, text views)
    
    typealias ReplyComposableViewController = ViewController & TalkPageReplyComposeDelegate & TalkPageTextViewLinkHandling
    private var viewController: ReplyComposableViewController?
    private(set) var commentViewModel: TalkPageCellCommentViewModel?
    
    private(set) var containerView: UIView?
    private var containerViewTopConstraint: NSLayoutConstraint?
    private var containerViewBottomConstraint: NSLayoutConstraint?
    private var contentViewBottomConstraint: NSLayoutConstraint?
    
    // Pan Gesture tracking properties
    private var dragHandleView: UIView?
    private var containerViewYUponDragBegin: CGFloat?
    
    private(set) var contentView: TalkPageReplyComposeContentView?
    
    private let containerPinnedTopSpacing = CGFloat(10)
    private let contentTopSpacing = CGFloat(15)
    
    enum DisplayMode {
        case full
        case partial
    }
    
    private var displayMode: DisplayMode = .partial
    private weak var authenticationManager: WMFAuthenticationManager?
    private weak var accessibilityFocusView: UIView?

    // MARK: Public
    
    func setupAndDisplay(in viewController: ReplyComposableViewController, commentViewModel: TalkPageCellCommentViewModel, authenticationManager: WMFAuthenticationManager?, accessibilityFocusView: UIView?) {
        
        guard self.commentViewModel == nil else {
            attemptChangeCommentViewModel(in: viewController, newCommentViewModel: commentViewModel)
            return
        }
        
        self.viewController = viewController
        self.commentViewModel = commentViewModel
        self.authenticationManager = authenticationManager
        self.accessibilityFocusView = accessibilityFocusView
        setupViews(in: viewController, commentViewModel: commentViewModel)
        apply(theme: viewController.theme)
        if UserDefaults.standard.wmf_userHasOnboardedToContributingToTalkPages {
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: contentView)
            }
        }
    }
    
    func attemptChangeCommentViewModel(in viewController: ReplyComposableViewController, newCommentViewModel: TalkPageCellCommentViewModel) {
        
        presentDismissConfirmationActionSheet(discardBlock: {
            self.closeAndReset(completion: { _ in
                self.setupAndDisplay(in: viewController, commentViewModel: newCommentViewModel, authenticationManager: self.authenticationManager, accessibilityFocusView: self.accessibilityFocusView)
            })
        })
    }
    
    func calculateLayout(in viewController: ReplyComposableViewController, newViewSize: CGSize? = nil, newKeyboardFrame: CGRect? = nil) {
        
        guard containerView != nil else {
            return
        }
        
        let keyboardHeight = newKeyboardFrame?.height ?? viewController.keyboardFrame?.height ?? 0
        
        contentViewBottomConstraint?.constant = keyboardHeight
        
        guard !shouldAlwaysPinToTop() else {
            displayMode = .full
            containerViewTopConstraint?.constant = containerPinnedTopSpacing
            return
        }
        
        // Aim for compose view to take up 60% of the screen for portrait, 80% for landscape
        let viewSize = newViewSize ?? viewController.view.bounds.size
        let isLandscape = viewSize.height < viewSize.width
        let topConstraintMultiplier = isLandscape ? 0.20 : 0.40
        let potentialTopConstraint = viewSize.height * (topConstraintMultiplier)
        
        // Add a little bit of extra padding if keyboard is still too tall
        let amountDisplaying = viewSize.height - potentialTopConstraint - keyboardHeight
        let extraPadding = max(0, 200 - amountDisplaying)
        let finalTopConstraint = potentialTopConstraint - extraPadding
        
        switch displayMode {
        case .full:
            containerViewTopConstraint?.constant = containerPinnedTopSpacing
        case .partial:
            containerViewTopConstraint?.constant = finalTopConstraint
        }
    }
    
    func closeAndReset(completion: ((UIView?) -> Void)? = nil) {
        
        contentView?.replyTextView.resignFirstResponder()
        
        animateOff {
            self.dragHandleView?.removeFromSuperview()
            self.dragHandleView = nil
            self.containerViewYUponDragBegin = nil
            
            self.containerView?.removeFromSuperview()
            self.containerView = nil
            self.containerViewTopConstraint = nil
            self.contentViewBottomConstraint = nil
            self.containerViewBottomConstraint = nil
            
            self.contentView?.removeFromSuperview()
            self.contentView = nil

            self.viewController = nil
            self.commentViewModel = nil
            
            self.displayMode = .partial
            
            let accessibilityFocusView = self.accessibilityFocusView
            self.accessibilityFocusView = nil
            
            completion?(accessibilityFocusView)
        }
    }
    
    var isLoading: Bool = false {
        didSet {
            contentView?.isLoading = isLoading
        }
    }

    var isShowing: Bool {
        return contentView != nil
    }
    
    // MARK: Private
    
    private func setupViews(in viewController: ReplyComposableViewController, commentViewModel: TalkPageCellCommentViewModel) {
        
        let containerView = UIView(frame: .zero)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.accessibilityViewIsModal = true
        
        addShadow(to: containerView)
        addDragHandle(to: containerView)
        viewController.view.addSubview(containerView)
        
        // set constraints
        let trailingConstraint = viewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        let bottomConstraint = viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        let leadingConstraint = viewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        let topConstraint = containerView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: containerPinnedTopSpacing)
        NSLayoutConstraint.activate([trailingConstraint, bottomConstraint, leadingConstraint, topConstraint])
        
        self.containerViewTopConstraint = topConstraint
        self.containerViewBottomConstraint = bottomConstraint
        self.containerView = containerView
        
        // sets more accurate top constraint
        calculateLayout(in: viewController)
        
        // add pan gesture
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userDidPanContainerView(_:)))
        containerView.addGestureRecognizer(panGestureRecognizer)
        
        addContentView(to: containerView, theme: viewController.theme, commentViewModel: commentViewModel, linkDelegate: viewController)
        animateOn()
    }
    
    private func addShadow(to containerView: UIView) {
        containerView.layer.masksToBounds = false
        containerView.layer.shadowOffset = CGSize(width: 0, height: -2)
        containerView.layer.shadowOpacity = 1.0
        containerView.layer.shadowRadius = 5
        containerView.layer.cornerRadius = 8
    }
    
    func addDragHandle(to containerView: UIView) {
        let dragHandleView = UIView(frame: .zero)
        dragHandleView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(dragHandleView)
        let dragHandleHeight = CGFloat(5)
        dragHandleView.cornerRadius = dragHandleHeight/2.5
        NSLayoutConstraint.activate([
            dragHandleView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            dragHandleView.widthAnchor.constraint(equalToConstant: 36),
            dragHandleView.heightAnchor.constraint(equalToConstant: dragHandleHeight),
            dragHandleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])
        
        self.dragHandleView = dragHandleView
    }
    
    private func addContentView(to containerView: UIView, theme: Theme, commentViewModel: TalkPageCellCommentViewModel, linkDelegate: TalkPageTextViewLinkHandling) {
        let contentView = TalkPageReplyComposeContentView(commentViewModel: commentViewModel, theme: theme, linkDelegate: linkDelegate)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        
        contentView.closeButton.addTarget(self, action: #selector(attemptClose), for: .touchUpInside)
        contentView.publishButton.addTarget(self, action: #selector(tappedPublish), for: .touchUpInside)
        
        let bottomConstraint = containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottomConstraint.priority = UILayoutPriority(999)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: contentTopSpacing),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomConstraint,
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])
        
        self.contentViewBottomConstraint = bottomConstraint
        self.contentView = contentView
    }
    
    private func shouldAlwaysPinToTop() -> Bool {
        
        guard let viewController = viewController else {
            return false
        }

        if UIAccessibility.isVoiceOverRunning {
            return true
        }
        
        return viewController.view.traitCollection.verticalSizeClass == .compact
    }
    
    @objc fileprivate func userDidPanContainerView(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        guard let viewController = viewController,
        let containerView = containerView else {
            gestureRecognizer.state = .ended
            return
        }
        
        let translationY = gestureRecognizer.translation(in: viewController.view).y

        switch gestureRecognizer.state {
        case .began:
            let containerViewYUponDragBegin = containerView.frame.origin.y - viewController.view.safeAreaInsets.top
            self.containerViewYUponDragBegin = containerViewYUponDragBegin
            
            calculateTopConstraintUponDrag(translationY: translationY)
        case .changed:
            
            guard containerViewYUponDragBegin != nil else {
                gestureRecognizer.state = .ended
                return
            }
            
            calculateTopConstraintUponDrag(translationY: translationY)
        case .ended:

            if translationY < -50 {
                displayMode = .full
                calculateLayout(in: viewController)
            } else if translationY > 50 {
                
                // If swiping down fast enough, attempt to close.
                
                let shouldAttemptClose = displayMode == .partial || (displayMode == .full && shouldAlwaysPinToTop())
                if shouldAttemptClose && gestureRecognizer.velocity(in: containerView).y > 100 {
                    attemptClose()
                } else {
                    displayMode = .partial
                    calculateLayout(in: viewController)
                }
            } else {
                calculateLayout(in: viewController)
            }
            
            // reset top constraint
            containerViewYUponDragBegin = nil
            
        default:
            break
        }
        
        viewController.view.setNeedsLayout()
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut) {
            viewController.view.layoutIfNeeded()
        }
    }
    
    private func calculateTopConstraintUponDrag(translationY: CGFloat) {
        
        guard let containerViewYUponDragBegin = containerViewYUponDragBegin else {
            return
        }
        
        // MAYBETODO: Consider maxing or mining out this value
        containerViewTopConstraint?.constant = containerViewYUponDragBegin + translationY
    }
    
// MARK: - Animate on/off
    
    private func animateOn() {
        
        guard let viewController = viewController,
              let containerView = containerView else {
            return
        }
        
        // manually move container off screen before animating to final constraints
        containerView.frame = CGRect(x: 0, y: viewController.view.bounds.height, width: viewController.view.bounds.width, height: viewController.view.bounds.height)
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
        
        // animate on screen
        viewController.view.setNeedsLayout()
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut) {
            viewController.view.layoutIfNeeded()
        }
    }
    
    private func animateOff(completion: @escaping () -> Void) {
        
        guard let viewController = viewController else {
            return
        }
        
        containerViewTopConstraint?.constant = viewController.view.bounds.height
        containerViewBottomConstraint?.constant = -viewController.view.bounds.height
        contentViewBottomConstraint?.constant = 0
        
        viewController.view.setNeedsLayout()
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut) {
            viewController.view.layoutIfNeeded()
        } completion: { _ in
            completion()
        }
    }
    
    func presentDismissConfirmationActionSheet(discardBlock: @escaping () -> Void) {
        let alertController = UIAlertController(title: Self.ActionSheetStrings.closeConfirmationTitle, message: nil, preferredStyle: .actionSheet)
        let discardAction = UIAlertAction(title: Self.ActionSheetStrings.closeConfirmationDiscard, style: .destructive) { _ in
            discardBlock()
        }
        
        let keepEditingAction = UIAlertAction(title: CommonStrings.talkPageCloseConfirmationKeepEditing, style: .cancel) { _ in
            
            guard let viewController = self.viewController else {
                return
            }
            
            self.calculateLayout(in: viewController)
        }
        
        alertController.addAction(discardAction)
        alertController.addAction(keepEditingAction)
        
        alertController.popoverPresentationController?.sourceView = contentView?.closeButton
        viewController?.present(alertController, animated: true)
    }
    
// MARK: - ACTIONS
    
    @objc func attemptClose() {
        contentView?.resignFirstResponder()
        
        if let replyText = contentView?.replyTextView.text,
           !replyText.isEmpty {
            presentDismissConfirmationActionSheet(discardBlock: {
                self.viewController?.closeReplyView()
            })
            return
        }
        
        viewController?.closeReplyView()
    }
    
    @objc private func tappedPublish() {

        if let talkPageURL = commentViewModel?.talkPageURL {
            EditAttemptFunnel.shared.logSaveIntent(pageURL: talkPageURL)
        }
        
        guard let commentViewModel = commentViewModel,
              let text = contentView?.replyTextView.text else {
            assertionFailure("Comment view model or replyTextView text is empty. Publish button should have been disabled.")
            return
        }
        
        contentView?.replyTextView.resignFirstResponder()
        
        guard let authenticationManager = authenticationManager,
              !authenticationManager.authStateIsPermanent else {
            isLoading = true
            viewController?.tappedPublish(text: text, commentViewModel: commentViewModel)
            return
        }
        
        guard let theme = viewController?.theme else {
            return
        }
        
        viewController?.wmf_showNotLoggedInUponPublishPanel(buttonTapHandler: { [weak self] buttonIndex in
            switch buttonIndex {
            case 0:
                break
            case 1:
                self?.isLoading = true
                self?.viewController?.tappedPublish(text: text, commentViewModel: commentViewModel)
            default:
                assertionFailure("Unrecognized button index in tap handler.")
            }
        }, theme: theme)
    }
}

extension TalkPageReplyComposeController: Themeable {
    func apply(theme: Theme) {
        containerView?.backgroundColor = theme.colors.paperBackground
        containerView?.layer.shadowColor = theme.colors.shadow.cgColor
        dragHandleView?.backgroundColor = WMFColor.gray675
        contentView?.apply(theme: theme)
    }
}
