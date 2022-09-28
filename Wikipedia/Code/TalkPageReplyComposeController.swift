import Foundation
import UIKit
import WMF

protocol TalkPageReplyComposeDelegate: AnyObject {
    func closeReplyView()
    func tappedPublish(text: String, commentViewModel: TalkPageCellCommentViewModel)
}

/// Class for coordinating talk page reply compose views
class TalkPageReplyComposeController {
    
    enum ActionSheetStrings {
        static let closeConfirmationTitle = WMFLocalizedString("talk-pages-reply-compose-close-confirmation-title", value: "Are you sure you want to discard this new reply?", comment: "Title of confirmation alert displayed to user when they attempt to close the new reply view after entering text.")
        static let closeConfirmationDiscard = WMFLocalizedString("talk-pages-topic-compose-close-confirmation-discard", value: "Discard Reply", comment: "Title of discard action, displayed within a confirmation alert to user when they attempt to close the new topic view after entering title or body text.")
    }
    
    // viewController - the view controller that triggered the reply compose screen
    // containerView - the view that contains the contentView. It has the drag handle and pan gesture attached.
    // contentView - the view with the reply compose UI elements (close button, publish button, text views)
    
    typealias ReplyComposableViewController = ViewController & TalkPageReplyComposeDelegate
    private var viewController: ReplyComposableViewController?
    private var commentViewModel: TalkPageCellCommentViewModel?
    
    private var containerView: UIView?
    private var containerViewTopConstraint: NSLayoutConstraint?
    private var containerViewBottomConstraint: NSLayoutConstraint?
    
    // Pan Gesture tracking properties
    private var dragHandleView: UIView?
    private var containerViewYUponDragBegin: CGFloat?
    
    private var contentView: TalkPageReplyComposeContentView?
    
    private let containerPinnedTopSpacing = CGFloat(10)
    private let contentTopSpacing = CGFloat(15)
    
    enum DisplayMode {
        case full
        case partial
    }
    
    private var displayMode: DisplayMode = .partial

    // MARK: Public
    
    func setupAndDisplay(in viewController: ReplyComposableViewController, commentViewModel: TalkPageCellCommentViewModel) {
        
        guard containerView == nil && contentView == nil else {
            return
        }
        
        self.viewController = viewController
        self.commentViewModel = commentViewModel
        
        setupViews(in: viewController, commentViewModel: commentViewModel)
        calculateLayout(in: viewController)
        apply(theme: viewController.theme)
    }
    
    func calculateLayout(in viewController: ReplyComposableViewController, newViewSize: CGSize? = nil, newKeyboardFrame: CGRect? = nil) {
        
        guard containerView != nil else {
            return
        }
        
        let keyboardHeight = newKeyboardFrame?.height ?? 0
        let viewHeight = newViewSize?.height ?? viewController.view.bounds.height
        
        containerViewBottomConstraint?.constant = keyboardHeight
        
        guard !shouldAlwaysPinToTop(newViewSize: newViewSize) else {
            displayMode = .full
            containerViewTopConstraint?.constant = containerPinnedTopSpacing
            return
        }
        
        switch displayMode {
        case .full:
            containerViewTopConstraint?.constant = containerPinnedTopSpacing
        case .partial:
            containerViewTopConstraint?.constant = viewHeight * (0.40)
        }
    }
    
    var additionalBottomContentInset: CGFloat {
        return 0
    }
    
    func reset() {
        dragHandleView?.removeFromSuperview()
        dragHandleView = nil
        containerViewYUponDragBegin = nil
        
        containerView?.removeFromSuperview()
        containerView = nil
        containerViewTopConstraint = nil
        containerViewBottomConstraint = nil
        
        contentView?.removeFromSuperview()
        contentView = nil

        viewController = nil
        commentViewModel = nil
        
        displayMode = .partial
    }
    
    var isLoading: Bool = false {
        didSet {
            contentView?.isLoading = isLoading
        }
    }
    
    // MARK: Private
    
    private func setupViews(in viewController: ReplyComposableViewController, commentViewModel: TalkPageCellCommentViewModel) {
        
        let containerView = UIView(frame: .zero)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        addShadow(to: containerView)
        addDragHandle(to: containerView)
        viewController.view.addSubview(containerView)
        
        let trailingConstraint = viewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        let bottomConstraint = viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        let leadingConstraint = viewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        let topConstraint = containerView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: containerPinnedTopSpacing)
        NSLayoutConstraint.activate([trailingConstraint, bottomConstraint, leadingConstraint, topConstraint])
        
        self.containerViewBottomConstraint = bottomConstraint
        self.containerViewTopConstraint = topConstraint

        self.containerView = containerView
        
        // add pan gesture
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userDidPanContainerView(_:)))
        containerView.addGestureRecognizer(panGestureRecognizer)
        
        addContentView(to: containerView, theme: viewController.theme, commentViewModel: commentViewModel)
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
    
    private func addContentView(to containerView: UIView, theme: Theme, commentViewModel: TalkPageCellCommentViewModel) {
        let contentView = TalkPageReplyComposeContentView(commentViewModel: commentViewModel, theme: theme)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        
        contentView.closeButton.addTarget(self, action: #selector(attemptClose), for: .touchUpInside)
        contentView.publishButton.addTarget(self, action: #selector(tappedPublish), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: contentTopSpacing),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])
        
        self.contentView = contentView
    }
    
    private func shouldAlwaysPinToTop(newViewSize: CGSize? = nil) -> Bool {
        guard let viewController = viewController else {
            return true
        }
        
        let viewSize = newViewSize ?? viewController.view.bounds.size
        
        return viewSize.width > viewSize.height
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
                }
                
                displayMode = .partial
                calculateLayout(in: viewController)
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
    
    func presentDismissConfirmationActionSheet() {
        let alertController = UIAlertController(title: Self.ActionSheetStrings.closeConfirmationTitle, message: nil, preferredStyle: .actionSheet)
        let discardAction = UIAlertAction(title: Self.ActionSheetStrings.closeConfirmationDiscard, style: .destructive) { _ in
            self.viewController?.closeReplyView()
        }
        
        let keepEditingAction = UIAlertAction(title: CommonStrings.talkPageCloseConfirmationKeepEditing, style: .cancel)
        
        alertController.addAction(discardAction)
        alertController.addAction(keepEditingAction)
        
        alertController.popoverPresentationController?.sourceView = contentView?.closeButton
        viewController?.present(alertController, animated: true)
    }
    
// MARK: - ACTIONS
    
    @objc private func attemptClose() {
        contentView?.resignFirstResponder()
        
        if let replyText = contentView?.replyTextView.text,
           !replyText.isEmpty {
            presentDismissConfirmationActionSheet()
            return
        }
        
        viewController?.closeReplyView()
    }
    
    @objc private func tappedPublish() {
        
        guard let commentViewModel = commentViewModel,
              let text = contentView?.replyTextView.text else {
            return
        }
        
        isLoading = true
        viewController?.tappedPublish(text: text, commentViewModel: commentViewModel)
    }
}

extension TalkPageReplyComposeController: Themeable {
    func apply(theme: Theme) {
        containerView?.backgroundColor = theme.colors.paperBackground
        containerView?.layer.shadowColor = theme.colors.shadow.cgColor
        dragHandleView?.backgroundColor = theme.colors.depthMarker
        contentView?.apply(theme: theme)
    }
}
