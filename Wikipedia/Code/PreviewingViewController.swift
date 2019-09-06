import UIKit

class PreviewingViewController: ThemeableViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForPreviewingIfAvailable()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unregisterForPreviewing()
    }
    
    // MARK - 3D Touch
    
    var previewingContext: UIViewControllerPreviewing?
    
    func unregisterForPreviewing() {
        guard let context = previewingContext else {
            return
        }
        unregisterForPreviewing(withContext: context)
    }
    
    func registerForPreviewingIfAvailable() {
        unregisterForPreviewing()
        guard traitCollection.forceTouchCapability == .available, let sourceView = viewIfLoaded else {
            return
        }
        previewingContext = registerForPreviewing(with: self, sourceView: sourceView)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        registerForPreviewingIfAvailable()
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension PreviewingViewController: UIViewControllerPreviewingDelegate {
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        return nil
    }
    
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
    }
}
