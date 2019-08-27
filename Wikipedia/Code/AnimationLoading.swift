
import Foundation

protocol AnimationLoading: class {
    var loadingAnimationViewController: LoadingAnimationViewController? { get set }
    func showLoadingAnimation(theme: Theme)
    func hideLoadingAnimation()
}

fileprivate let timeoutSeconds = 0.5

extension AnimationLoading where Self: UIViewController {
    func showLoadingAnimation(theme: Theme) {
        if loadingAnimationViewController == nil {
            loadingAnimationViewController = LoadingAnimationViewController.init(nibName: "LoadingAnimationViewController", bundle: nil)
            wmf_add(childController: loadingAnimationViewController, andConstrainToEdgesOfContainerView: view)
        }
        
        loadingAnimationViewController?.apply(theme: theme)
        loadingAnimationViewController?.view.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeoutSeconds) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            if let view = self.loadingAnimationViewController?.view,
                view.superview != nil {
                self.loadingAnimationViewController?.view.isHidden = false
            }
        }
    }
    
    
    
    func hideLoadingAnimation() {
        loadingAnimationViewController?.willMove(toParent: nil)
        loadingAnimationViewController?.view.removeFromSuperview()
        loadingAnimationViewController?.removeFromParent()
        loadingAnimationViewController = nil
    }
}

@objc extension UIViewController {
    
    @objc func objcShowLoadingAnimation(theme: Theme, cancelBlock: @escaping () -> Void) -> LoadingAnimationViewController {
        let loadingAnimationViewController = LoadingAnimationViewController.init(nibName: "LoadingAnimationViewController", bundle: nil)
        loadingAnimationViewController.cancelBlock = cancelBlock
        wmf_add(childController: loadingAnimationViewController, andConstrainToEdgesOfContainerView: view)
        
        loadingAnimationViewController.apply(theme: theme)
        loadingAnimationViewController.view.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeoutSeconds) {
            
            if let view = loadingAnimationViewController.view,
                view.superview != nil {
                loadingAnimationViewController.view.isHidden = false
            }
        }
        
        return loadingAnimationViewController
    }
    
    @objc func objcHideLoadingAnimation(with loadingAnimationViewController: LoadingAnimationViewController?) {
        loadingAnimationViewController?.willMove(toParent: nil)
        loadingAnimationViewController?.view.removeFromSuperview()
        loadingAnimationViewController?.removeFromParent()
    }
}
