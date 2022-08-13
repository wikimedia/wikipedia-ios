import Foundation
import UIKit
import WMF

/// Class for coordinating talk page reply compose views
class TalkPageReplyComposeController {
    
    private(set) var containerView: UIView?
    private var containerViewTopConstraint: NSLayoutConstraint?
    private var containerViewBottomConstraint: NSLayoutConstraint?
    private var containerViewHeightConstraint: NSLayoutConstraint?
    
    private var contentView: TalkPageReplyComposeContentView?
    
    private let containerPinnedTopSpacing = CGFloat(10)
    private let contentTopSpacing = CGFloat(15)

    // MARK: Public
    
    func setupAndDisplay(in viewController: TalkPageViewController, theme: Theme) {
        
        guard containerView == nil && contentView == nil else {
            return
        }
        
        setupViews(in: viewController)
        calculateLayout(in: viewController)
        apply(theme: theme)
    }
    
    func calculateLayout(in viewController: ViewController, newViewSize: CGSize? = nil, newKeyboardFrame: CGRect? = nil) {
        
        containerViewBottomConstraint?.constant = newKeyboardFrame?.height ?? 0
        
        let viewHeight = newViewSize?.height ?? viewController.view.frame.height
        let oneFifthViewHeight = viewHeight / 5
        
        containerViewHeightConstraint?.constant = oneFifthViewHeight
        
        // always pin compact vertical size classes
        guard viewController.traitCollection.verticalSizeClass != .compact else {
            toggleConstraints(shouldPinToTop: true)
            return
        }

        toggleConstraints(shouldPinToTop: false)
    }
    
    // MARK: Private
    
    private func setupViews(in viewController: ViewController) {
        let containerView = UIView(frame: .zero)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        addShadow(to: containerView)
        viewController.view.addSubview(containerView)
        
        // always active constraints
        let trailingConstraint = viewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        let bottomConstraint = viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        let leadingConstraint = viewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        NSLayoutConstraint.activate([trailingConstraint, bottomConstraint, leadingConstraint])
        
        self.containerViewBottomConstraint = bottomConstraint
        
        // sometimes inactive constraints
        self.containerViewTopConstraint = containerView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: containerPinnedTopSpacing)
        self.containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 0)

        self.containerView = containerView
        
        addContentView(to: containerView)
    }
    
    private func addShadow(to containerView: UIView) {
        containerView.layer.masksToBounds = false
        containerView.layer.shadowOffset = CGSize(width: 0, height: -2)
        containerView.layer.shadowOpacity = 1.0
        containerView.layer.shadowRadius = 5
        containerView.layer.cornerRadius = 8
    }
    
    private func addContentView(to containerView: UIView) {
        let contentView = TalkPageReplyComposeContentView(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: contentTopSpacing),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
        ])
        
        self.contentView = contentView
    }
    
    private func toggleConstraints(shouldPinToTop: Bool) {
        if shouldPinToTop {
            containerViewHeightConstraint?.isActive = false
            containerViewTopConstraint?.isActive = true
        } else {
            containerViewTopConstraint?.isActive = false
            containerViewHeightConstraint?.isActive = true
        }
    }
}

extension TalkPageReplyComposeController: Themeable {
    func apply(theme: Theme) {
        containerView?.backgroundColor = theme.colors.paperBackground
        containerView?.layer.shadowColor = theme.colors.shadow.cgColor
        contentView?.apply(theme: theme)
    }
}
