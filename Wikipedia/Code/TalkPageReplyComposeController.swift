import Foundation
import UIKit
import WMF

/// Class for coordinating talk page reply compose views
class TalkPageReplyComposeController {
    
    // viewController - the view controller that triggered the reply compose screen
    // containerView - the view that contains the contentView. It has the drag handle and pan gesture attached.
    // contentView - the view with the reply compose UI elements (close button, publish button, text views)
    
    private var viewController: ViewController?
    
    private var containerView: UIView?
    private var containerViewTopConstraint: NSLayoutConstraint?
    private var containerViewBottomConstraint: NSLayoutConstraint?
    private var containerViewHeightConstraint: NSLayoutConstraint?
    
    // Pan Gesture tracking properties
    private var safeAreaBackgroundView: UIView?
    private var dragHandleView: UIView?
    private var containerViewYUponDragBegin: CGFloat?
    private var containerViewWasPinnedToTopUponDragBegin: Bool?
    
    private var contentView: TalkPageReplyComposeContentView?
    
    private let containerPinnedTopSpacing = CGFloat(10)
    private let contentTopSpacing = CGFloat(15)

    // MARK: Public
    
    func setupAndDisplay(in viewController: ViewController) {
        
        guard containerView == nil && contentView == nil else {
            return
        }
        
        self.viewController = viewController
        
        setupViews(in: viewController)
        calculateLayout(in: viewController)
        apply(theme: viewController.theme)
    }
    
    func calculateLayout(in viewController: ViewController, newViewSize: CGSize? = nil, newKeyboardFrame: CGRect? = nil) {
        
        containerViewBottomConstraint?.constant = newKeyboardFrame?.height ?? 0
        
        let viewHeight = newViewSize?.height ?? viewController.view.frame.height
        let oneFourthViewHeight = viewHeight / 4
        
        containerViewHeightConstraint?.constant = oneFourthViewHeight
        
        toggleConstraints(shouldPinToTop: shouldAlwaysPinToTop)
    }
    
    var additionalBottomContentInset: CGFloat {
        return containerViewHeightConstraint?.constant ?? 0
    }
    
    // MARK: Private
    
    private func setupViews(in viewController: ViewController) {
        
        setupSafeAreaBackgroundView(in: viewController)
        
        let containerView = UIView(frame: .zero)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        addShadow(to: containerView)
        addDragHandle(to: containerView)
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
        
        // add pan gesture
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userDidPanContainerView(_:)))
        containerView.addGestureRecognizer(panGestureRecognizer)
        
        addContentView(to: containerView, theme: viewController.theme)
    }
    
    private func setupSafeAreaBackgroundView(in viewController: ViewController) {
        let backgroundView = UIView(frame: .zero)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(backgroundView)
        
        NSLayoutConstraint.activate([
            viewController.view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            viewController.view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            viewController.view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            viewController.view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
        
        backgroundView.isHidden = true
        self.safeAreaBackgroundView = backgroundView
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
    
    private func addContentView(to containerView: UIView, theme: Theme) {
        let contentView = TalkPageReplyComposeContentView(theme: theme)
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
    
    private var shouldAlwaysPinToTop: Bool {
        guard let viewController = viewController else {
            return false
        }
        
        return viewController.traitCollection.verticalSizeClass == .compact
    }
    
    @objc fileprivate func userDidPanContainerView(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        guard let viewController = viewController,
        let containerView = containerView,
        let safeAreaBackgroundView = safeAreaBackgroundView else {
            gestureRecognizer.state = .ended
            return
        }
        
        let translationY = gestureRecognizer.translation(in: viewController.view).y

        switch gestureRecognizer.state {
        case .began:
            let containerViewSafeAreaFrame = viewController.view.convert(containerView.frame, to: safeAreaBackgroundView)
            let containerViewYUponDragBegin = containerViewSafeAreaFrame.origin.y
            self.containerViewYUponDragBegin = containerViewYUponDragBegin
            
            self.containerViewWasPinnedToTopUponDragBegin = containerViewYUponDragBegin == containerPinnedTopSpacing
            
            calculateTopConstraintUponDrag(translationY: translationY)
            toggleConstraints(shouldPinToTop: true)
        case .changed:
            
            guard containerViewYUponDragBegin != nil else {
                gestureRecognizer.state = .ended
                return
            }
            
            calculateTopConstraintUponDrag(translationY: translationY)
            toggleConstraints(shouldPinToTop: true)
        case .ended:

            if translationY < -50 {
                containerViewTopConstraint?.constant = containerPinnedTopSpacing
                toggleConstraints(shouldPinToTop: true)
            } else if translationY > 50 && !shouldAlwaysPinToTop {
                toggleConstraints(shouldPinToTop: false)
            } else {
                // wasn't dragged far enough in either direction, so reset back to where it was when pan gesture started
                toggleConstraints(shouldPinToTop: (containerViewWasPinnedToTopUponDragBegin ?? false))
            }
            
            // reset top constraint
            containerViewTopConstraint?.constant = containerPinnedTopSpacing
            containerViewYUponDragBegin = nil
            containerViewWasPinnedToTopUponDragBegin = nil
            
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
        
        let maxY = containerViewYUponDragBegin + 10
        let minY = containerViewYUponDragBegin - 10

        containerViewTopConstraint?.constant = max(min(containerViewYUponDragBegin + translationY, maxY), minY)
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
        dragHandleView?.backgroundColor = theme.colors.depthMarker
        contentView?.apply(theme: theme)
    }
}
