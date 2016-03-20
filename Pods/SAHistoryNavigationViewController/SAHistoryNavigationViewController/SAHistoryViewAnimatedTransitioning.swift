//
//  SAHistoryViewAnimatedTransitioning.swift
//  SAHistoryNavigationViewController
//
//  Created by 鈴木大貴 on 2015/10/26.
//  Copyright (c) 2015年 鈴木大貴. All rights reserved.
//

import UIKit

class SAHistoryViewAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    //MARK: - Static Constants
    static private let Duration: NSTimeInterval = 0.25
    static private let Scale: CGFloat = 0.7
    
    //MARK: - Properties
    private var isPresenting = true
    
    //MARK: - Initializers
    init(isPresenting: Bool) {
        super.init()
        self.isPresenting = isPresenting
    }
    
    //MARK - Life cycle
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return SAHistoryViewAnimatedTransitioning.Duration
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let containerView = transitionContext.containerView() else {
            return
        }
        
        guard let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
            return
        }
        
        guard let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) else {
            return
        }
        
        if isPresenting {
            pushAniamtion(transitionContext, containerView: containerView, toVC: toVC, fromVC: fromVC)
        } else {
            popAniamtion(transitionContext, containerView: containerView, toVC: toVC, fromVC: fromVC)
        }
    }
}

//MARK: - Animations
extension SAHistoryViewAnimatedTransitioning {
    private func pushAniamtion(transitionContext: UIViewControllerContextTransitioning, containerView: UIView, toVC: UIViewController, fromVC: UIViewController) {
        guard let hvc = toVC as? SAHistoryViewController else {
            return
        }
        
        containerView.addSubview(toVC.view)
        fromVC.view.hidden = true
        hvc.view.frame = containerView.bounds
        hvc.collectionView.transform = CGAffineTransformIdentity

        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: .CurveEaseOut, animations: {
            hvc.collectionView.transform = CGAffineTransformMakeScale(SAHistoryViewAnimatedTransitioning.Scale, SAHistoryViewAnimatedTransitioning.Scale)
        }) { finished in
            let cancelled = transitionContext.transitionWasCancelled()
            if cancelled {
                fromVC.view.hidden = false
                hvc.collectionView.transform = CGAffineTransformIdentity
                hvc.view.removeFromSuperview()
            } else {
                hvc.view.hidden = false
                fromVC.view.removeFromSuperview()
            }
            transitionContext.completeTransition(!cancelled)
        }
    }
    
    private func popAniamtion(transitionContext: UIViewControllerContextTransitioning, containerView: UIView, toVC: UIViewController, fromVC: UIViewController) {
        guard let hvc = fromVC as? SAHistoryViewController else {
            return
        }
        
        containerView.addSubview(toVC.view)
        toVC.view.hidden = true
        hvc.view.frame = containerView.bounds
        hvc.collectionView.transform = CGAffineTransformMakeScale(SAHistoryViewAnimatedTransitioning.Scale, SAHistoryViewAnimatedTransitioning.Scale)
        
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: .CurveEaseOut, animations: {
            hvc.collectionView.transform = CGAffineTransformIdentity
            hvc.scrollToSelectedIndex(false)
        }) { finished in
            let cancelled = transitionContext.transitionWasCancelled()
            if cancelled {
                hvc.collectionView.transform = CGAffineTransformIdentity
                toVC.view.removeFromSuperview()
            } else {
                toVC.view.hidden = false
                hvc.view.removeFromSuperview()
            }
            transitionContext.completeTransition(!cancelled)
        }
    }
}
