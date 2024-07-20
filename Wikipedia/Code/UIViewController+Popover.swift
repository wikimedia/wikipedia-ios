import Foundation

extension UIViewController {
    func wmf_presentDynamicHeightPopoverViewController(item: UIBarButtonItem, title: String, message: String, width: CGFloat, duration: TimeInterval) {
        wmf_presentDynamicHeightPopoverViewController(title: title, message: message, width: width, duration: duration) { presenter in
            presenter.barButtonItem = item
        }
    }
    
    func wmf_presentDynamicHeightPopoverViewController(sourceRect: CGRect, title: String, message: String, width: CGFloat, duration: TimeInterval) {
        wmf_presentDynamicHeightPopoverViewController(title: title, message: message, width: width, duration: duration) { [weak self] presenter in
            
            guard let self else {
                return
            }
            
            presenter.sourceView = self.view
            presenter.sourceRect = sourceRect
        }
    }
    
    private func wmf_presentDynamicHeightPopoverViewController(title: String, message: String, width: CGFloat, duration: TimeInterval, presenterConfigurationBlock: (UIPopoverPresentationController) -> Void) {
        guard let popoverVC = wmf_dynamicHeightPopoverViewController(title: title, message: message, width: width, duration: duration, presenterConfigurationBlock: presenterConfigurationBlock) else {
            return
        }
        
        present(popoverVC, animated: false) {
            if duration > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                    self?.dismissPopover(popoverVC)
                }
            }
        }
    }
    
    private func dismissPopover(_ popoverVC: UIViewController) {
        if presentedViewController == popoverVC {
            dismiss(animated: true)
        }
    }
    
    private func wmf_dynamicHeightPopoverViewController(title: String, message: String, width: CGFloat, duration: TimeInterval, presenterConfigurationBlock: (UIPopoverPresentationController) -> Void) -> UIViewController? {
        let popoverVC = WMFBarButtonItemPopoverMessageViewController.wmf_initialViewControllerFromClassStoryboard()
        popoverVC?.modalPresentationStyle = .popover
        popoverVC?.messageTitle = title
        popoverVC?.message = message
        popoverVC?.width = width
        
        guard let popoverVC,
              let presenter = popoverVC.popoverPresentationController else {
            return nil
        }
        
        presenter.delegate = popoverVC
        
        presenterConfigurationBlock(presenter)
        
        if let themeableSelf = self as? ThemeableViewController {
            popoverVC.apply(theme: themeableSelf.theme)
            presenter.backgroundColor = themeableSelf.theme.colors.paperBackground
        }
        
        return popoverVC
    }
}
